from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
import pandas as pd
import time
import re
from collections import defaultdict


# ============================================================
# 1. Crawl хийх URL-ууд
# ============================================================

URLS = [
    "https://www.facebook.com/p/Nomadabe-Travel-61564497080885/",
    "https://www.instagram.com/nomadabe.travel/",
]

OUTPUT_CSV = "social_posts_raw.csv"
OUTPUT_MD = "social_knowledge.md"

SCROLL_COUNT = 20


# ============================================================
# 2. Text цэвэрлэх
# ============================================================

def clean_text(text: str) -> str:
    if not text:
        return ""

    text = re.sub(r"\s+", " ", text)

    remove_phrases = [
        "See more",
        "See translation",
        "View all comments",
        "View replies",
        "Reply",
        "Like",
        "Share",
        "Comment",
        "Follow",
        "Message",
    ]

    for phrase in remove_phrases:
        text = text.replace(phrase, "")

    return text.strip()


# ============================================================
# 3. Source type ялгах
# ============================================================

def detect_source_type(url: str) -> str:
    if "facebook.com" in url:
        return "Facebook"
    if "instagram.com" in url:
        return "Instagram"
    return "Unknown"


# ============================================================
# 4. Хэрэггүй UI text filter
# ============================================================

def is_noise_text(text: str) -> bool:
    if not text:
        return True

    if len(text) < 30:
        return True

    lower = text.lower()

    noise_words = [
        "log in",
        "sign up",
        "forgot password",
        "create new account",
        "meta",
        "privacy",
        "terms",
        "cookies",
        "help",
        "about",
        "locations",
        "threads",
        "contact uploading",
        "non-users",
        "learn more",
        "not now",
        "save login info",
        "followers",
        "following",
        "posts",
        "reels",
        "tagged",
        "explore",
        "search",
        "home",
        "profile",
    ]

    if any(word in lower for word in noise_words):
        return True

    # Дан тоо эсвэл богино UI count хасна
    if re.fullmatch(r"[\d\s,\.KkMm]+", text):
        return True

    return False


# ============================================================
# 5. Нэг URL crawler
# ============================================================

def crawl_public_page(page, url: str) -> list[dict]:
    posts = []
    source_type = detect_source_type(url)

    print(f"\nCrawling: {source_type} -> {url}")

    try:
        page.goto(url, wait_until="domcontentloaded", timeout=60000)
        time.sleep(5)

        # Popup хаах оролдлого
        try:
            page.keyboard.press("Escape")
            time.sleep(1)
        except Exception:
            pass

        # Scroll
        for i in range(SCROLL_COUNT):
            page.mouse.wheel(0, 3000)
            time.sleep(2)
            print(f"  Scroll {i + 1}/{SCROLL_COUNT}")

        html = page.content()
        soup = BeautifulSoup(html, "html.parser")

        raw_lines = soup.get_text("\n", strip=True).split("\n")

        for line in raw_lines:
            text = clean_text(line)

            if is_noise_text(text):
                continue

            posts.append({
                "source_type": source_type,
                "source_url": url,
                "text": text,
            })

    except Exception as e:
        print(f"Error crawling {url}: {e}")

    return posts


# ============================================================
# 6. Raw post duplicate remove
# ============================================================

def remove_duplicates(posts: list[dict]) -> list[dict]:
    unique_posts = []
    seen = set()

    for post in posts:
        if not isinstance(post, dict):
            continue

        text = post.get("text", "")
        source_type = post.get("source_type", "")

        normalized = re.sub(r"\s+", " ", text).strip().lower()
        key = (source_type, normalized[:180])

        if key not in seen:
            seen.add(key)
            unique_posts.append(post)

    return unique_posts


# ============================================================
# 7. CSV хадгалах
# ============================================================

def save_csv(posts: list[dict]) -> None:
    df = pd.DataFrame(posts)
    df.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"\nCSV saved: {OUTPUT_CSV}")


# ============================================================
# 8. Helper functions
# ============================================================

def has_any(text: str, keywords: list[str]) -> bool:
    lower = text.lower()
    return any(keyword.lower() in lower for keyword in keywords)


def dedup_text_list(items: list[str]) -> list[str]:
    result = []
    seen = set()

    for item in items:
        if not isinstance(item, str):
            continue

        item = item.strip()
        if not item:
            continue

        normalized = re.sub(r"\s+", " ", item).strip().lower()
        key = normalized[:180]

        if key not in seen:
            seen.add(key)
            result.append(item)

    return result


def dedup_post_list(posts: list[dict]) -> list[dict]:
    result = []
    seen = set()

    for post in posts:
        if not isinstance(post, dict):
            continue

        text = post.get("text", "")
        normalized = re.sub(r"\s+", " ", text).strip().lower()
        key = normalized[:180]

        if key not in seen:
            seen.add(key)
            result.append(post)

    return result


def extract_dates(text: str) -> list[str]:
    patterns = [
        r"\d{4}\s*оны\s*\d{1,2}\s*[-–]\s*р\s*сарын\s*\d{1,2}",
        r"\d{4}\s*оны\s*\d{1,2}\s*сарын\s*\d{1,2}",
        r"\d{1,2}\s*[-–]\s*р\s*сарын\s*\d{1,2}",
        r"\d{1,2}:\d{2}\s*[-–]\s*\d{1,2}:\d{2}",
    ]

    found = []

    for pattern in patterns:
        found.extend(re.findall(pattern, text))

    return dedup_text_list(found)


def extract_cta(text: str) -> list[str]:
    patterns = [
        r"\d+\s*гэж\s*(?:коммент\s*)?бич(?:ихэд|ээд)?[^\.。!]*",
        r"дэлгэрэнгүй мэдээлэл авах[^\.。!]*",
        r"амжиж бүртгүүл[^\.。!]*",
        r"суудал цөөн үлд[^\.。!]*",
    ]

    found = []

    for pattern in patterns:
        matches = re.findall(pattern, text, flags=re.IGNORECASE)
        found.extend(matches)

    return dedup_text_list(found)


def write_bullets(f, items: list[str], max_items: int | None = None) -> None:
    if not items:
        f.write("- Мэдээлэл олдсонгүй.\n")
        return

    selected = items[:max_items] if max_items else items

    for item in selected:
        item = item.strip()
        if item:
            f.write(f"- {item}\n")


def write_section(f, title: str, items: list[str], max_items: int | None = None) -> None:
    f.write(f"\n## {title}\n\n")
    write_bullets(f, items, max_items=max_items)
    f.write("\n")


# ============================================================
# 9. Аяллын компанийн knowledge extraction
# ============================================================

def build_structured_knowledge(posts: list[dict]) -> dict:
    knowledge = {
        "company_overview": [],
        "address": [],
        "services": [],
        "business_travel": [],
        "leisure_travel": [],
        "events_expos": defaultdict(list),
        "included_services": [],
        "business_support": [],
        "logistics": [],
        "promotions": [],
        "contact_cta": [],
        "testimonials": [],
        "travel_trends": [],
        "raw_useful_posts": [],
    }

    expo_keywords = {
        "Canton Fair бизнес аялал": [
            "canton fair",
            "кантон",
            "139-р canton",
            "худалдан авалт",
            "импортын бизнес",
        ],
        "SNEC PV+ 2026 бизнес аялал": [
            "snec",
            "pv+",
            "нарны эрчим хүч",
            "battery storage",
            "ухаалаг эрчим хүч",
        ],
        "SIAL Shanghai Expo бизнес аялал": [
            "sial",
            "shanghai sial",
            "хүнсний бизнес",
            "хүнсний бүтээгдэхүүн",
        ],
    }

    for post in posts:
        if not isinstance(post, dict):
            continue

        text = post.get("text", "").strip()

        if not text:
            continue

        useful = False

        # Компанийн тухай
        if has_any(text, [
            "бизнес аялал",
            "хөтөлбөртэй амралт",
            "амралт зугаалга",
            "чөлөөт аялал",
            "tour agency",
            "travel service",
            "travel company",
        ]):
            knowledge["company_overview"].append(text)
            knowledge["services"].append(text)
            useful = True

        # Байршил
        if has_any(text, [
            "minister tower",
            "olympic street",
            "ulaanbaatar",
            "улаанбаатар",
            "mongolia",
        ]):
            knowledge["address"].append(text)
            useful = True

        # Бизнес аялал
        if has_any(text, [
            "бизнес аялал",
            "бизнесээ тэл",
            "бизнес эхлэх",
            "бизнесээ өргөжүүлэх",
            "бизнесийн зорилго",
            "бизнесийн зөвлөгөө",
            "know-how",
            "импорт",
            "үйлдвэрлэгч",
            "нийлүүлэгч",
        ]):
            knowledge["business_travel"].append(text)
            useful = True

        # Чөлөөт / амралт аялал
        if has_any(text, [
            "чөлөөт аялал",
            "амралт зугаалга",
            "шинэ улс",
            "шинэ дурсамж",
            "шинэ адал явдал",
            "аяллын сайхан он",
        ]):
            knowledge["leisure_travel"].append(text)
            useful = True

        # Expo/event аялал
        for expo_name, keywords in expo_keywords.items():
            if has_any(text, keywords):
                knowledge["events_expos"][expo_name].append(text)
                useful = True

        # Аяллын багцад багтах зүйлс
        if has_any(text, [
            "нислэгийн тийз",
            "зочид буудал",
            "дата сим",
            "data sim",
            "esim",
            "аяллын даатгал",
            "орчуулагч",
            "хөтөч",
            "бүх зүйл багтсан",
            "нэмэлт зардалгүй",
            "цүнхээ үүрээд",
        ]):
            knowledge["included_services"].append(text)
            useful = True

        # Бизнес зөвлөгөө / know-how
        if has_any(text, [
            "гэрээ хэлцэл",
            "маркетинг",
            "төлөвлөлт",
            "санхүүжилт",
            "зээл",
            "борлуулалт",
            "бараа бүтээгдэхүүн",
            "брэнд",
            "сүлжээ дэлгүүр",
            "банк",
            "банк бус",
            "төлбөр тооцоо",
            "судалгаа хийх",
            "амжилттай борлуулах",
        ]):
            knowledge["business_support"].append(text)
            useful = True

        # Логистик
        if has_any(text, [
            "логистик",
            "карго",
            "тээвэр",
            "m&m",
            "ачааг",
            "алдагдах эрсдэл",
            "найдвартай",
            "хямд тээвэр",
        ]):
            knowledge["logistics"].append(text)
            useful = True

        # Урамшуулал
        if has_any(text, [
            "10%",
            "буцаан олголт",
            "early bird",
            "урамшуулал",
            "онцгой үнэ",
            "онцгой 2 урамшуулал",
        ]):
            knowledge["promotions"].append(text)
            useful = True

        # CTA
        ctas = extract_cta(text)
        if ctas:
            knowledge["contact_cta"].extend(ctas)
            useful = True

        # Сэтгэгдэл
        if has_any(text, [
            "үнэхээр сэтгэлтэй",
            "uneheer setgeltei",
            "mundag hamt olon",
            "сайхан аялаад",
            "saikhan ayalaad",
            "амжилт хүсье",
            "bayarlalaa",
            "баярлалаа",
        ]):
            knowledge["testimonials"].append(text)
            useful = True

        # Салбарын чиг хандлага
        if has_any(text, [
            "аяллын бүтээгдэхүүний чиг хандлага",
            "аяллын технологи",
            "ухаалаг аяллын шийдэл",
            "салбар бүрийн чиг хандлага",
            "үйлдвэрлэгчид",
            "oem",
            "odm",
            "инноваци",
            "шинэ чиг хандлага",
        ]):
            knowledge["travel_trends"].append(text)
            useful = True

        if useful:
            knowledge["raw_useful_posts"].append(post)

    # String list-үүдийг dedup хийнэ
    for key, value in knowledge.items():
        if key == "raw_useful_posts":
            continue

        if key == "events_expos":
            continue

        if isinstance(value, list):
            knowledge[key] = dedup_text_list(value)

    # raw_useful_posts нь dict list тул тусад нь dedup хийнэ
    knowledge["raw_useful_posts"] = dedup_post_list(knowledge["raw_useful_posts"])

    # events_expos доторх list-үүдийг dedup хийнэ
    for expo_name in list(knowledge["events_expos"].keys()):
        knowledge["events_expos"][expo_name] = dedup_text_list(
            knowledge["events_expos"][expo_name]
        )

    return knowledge


# ============================================================
# 10. Knowledge markdown хадгалах
# ============================================================

def save_structured_markdown(posts: list[dict]) -> None:
    knowledge = build_structured_knowledge(posts)

    with open(OUTPUT_MD, "w", encoding="utf-8") as f:
        f.write("# Nomadabe Travel - Компанийн Knowledge Base\n\n")
        f.write("Энэ knowledge base нь Nomadabe Travel-ийн Facebook болон Instagram public content-оос crawler-оор авсан мэдээлэл дээр үндэслэн бүтээгдсэн.\n\n")
        f.write("---\n\n")

        # ====================================================
        # 1. Компанийн үндсэн мэдээлэл
        # ====================================================

        f.write("## 1. Компанийн үндсэн мэдээлэл\n\n")

        f.write("### Компанийн нэр\n\n")
        f.write("- Nomadabe Travel\n\n")

        f.write("### Үйл ажиллагааны чиглэл\n\n")
        f.write("Nomadabe Travel нь social content дээрээ бизнес аялал, хөтөлбөртэй амралт зугаалга болон чөлөөт аяллыг мэргэжлийн түвшинд зохион байгуулах чиглэлтэй аяллын компани гэж харагдаж байна.\n\n")

        f.write("### Эх сурвалжаас илэрсэн мэдээлэл\n\n")
        write_bullets(f, knowledge["company_overview"], max_items=8)
        f.write("\n")

        # ====================================================
        # 2. Байршил
        # ====================================================

        write_section(
            f,
            "2. Байршил ба холбоотой мэдээлэл",
            knowledge["address"],
            max_items=8
        )

        # ====================================================
        # 3. Үндсэн үйлчилгээ
        # ====================================================

        f.write("## 3. Үндсэн үйлчилгээ\n\n")
        f.write("Crawler-оор авсан social post-ууд дээр үндэслэн дараах үйлчилгээний чиглэлүүд илэрсэн:\n\n")
        f.write("- Бизнес аялал\n")
        f.write("- Олон улсын үзэсгэлэн / expo-д оролцох аялал\n")
        f.write("- Хөтөлбөртэй амралт зугаалга\n")
        f.write("- Чөлөөт аялал\n")
        f.write("- Импорт, худалдан авалт, бизнес хөгжлийн зорилготой аялал\n")
        f.write("- Бизнес зөвлөгөө, know-how бүхий аяллын багц\n")
        f.write("- Тээвэр, логистикийн зөвлөгөөтэй аялал\n\n")

        # ====================================================
        # 4. Бизнес аяллын чиглэл
        # ====================================================

        f.write("## 4. Бизнес аяллын чиглэл\n\n")
        f.write("Nomadabe Travel-ийн social content дээр бизнес аялал нь зөвхөн аялах биш, харин бизнесийн зорилго биелүүлэхэд чиглэсэн үйлчилгээтэй гэж харагдаж байна.\n\n")

        f.write("### Илэрсэн post мэдээллүүд\n\n")
        write_bullets(f, knowledge["business_travel"], max_items=15)
        f.write("\n")

        # ====================================================
        # 5. Expo аяллууд
        # ====================================================

        f.write("## 5. Онцлох аяллууд ба үзэсгэлэн / Expo event-үүд\n\n")

        if not knowledge["events_expos"]:
            f.write("- Expo/event аяллын мэдээлэл олдсонгүй.\n\n")
        else:
            for expo_name, expo_posts in knowledge["events_expos"].items():
                f.write(f"### {expo_name}\n\n")

                # Expo summary-г keyword-ээр гаргана
                if "Canton" in expo_name:
                    f.write("#### Аяллын тухай\n\n")
                    f.write("Canton Fair бизнес аялал нь импортын бизнес эхлэх, бизнесээ өргөжүүлэх, бараа бүтээгдэхүүн, тоног төхөөрөмж, үйлдвэрлэгч, брэнд судлах зорилготой аялал гэж илэрсэн.\n\n")

                    f.write("#### Хэнд тохиромжтой вэ?\n\n")
                    f.write("- Импортын бизнес эхлүүлэх гэж буй хүн\n")
                    f.write("- Одоо байгаа бизнесээ өргөжүүлэх гэж буй бизнес эрхлэгч\n")
                    f.write("- Шинэ бараа бүтээгдэхүүн хайж буй худалдаачин\n")
                    f.write("- Үйлдвэрлэгч, нийлүүлэгчтэй шууд холбогдох хүсэлтэй хүн\n")
                    f.write("- Сүлжээ дэлгүүрт бараа бүтээгдэхүүн нийлүүлэхээр төлөвлөж буй бизнес\n\n")

                    f.write("#### Аяллаар авах боломжтой мэдлэг\n\n")
                    f.write("- Бараа бүтээгдэхүүн хэрхэн сонгох\n")
                    f.write("- Брэнд хэрхэн судлах\n")
                    f.write("- Бүтээгдэхүүн Монголд борлуулах боломжийг хэрхэн үнэлэх\n")
                    f.write("- Санхүүжилт хэрхэн босгох\n")
                    f.write("- Сүлжээ дэлгүүрээр борлуулалт хийх арга\n")
                    f.write("- Банк болон банк бусын зээлийн шалгуур\n")
                    f.write("- Тээвэр, логистикийн шийдэл\n\n")

                elif "SNEC" in expo_name:
                    f.write("#### Аяллын тухай\n\n")
                    f.write("SNEC PV+ 2026 нь нарны эрчим хүч, battery storage, ухаалаг эрчим хүчний салбарын олон улсын томоохон үзэсгэлэн гэж илэрсэн.\n\n")

                    f.write("#### Хэнд тохиромжтой вэ?\n\n")
                    f.write("- Нарны эрчим хүчний бизнес сонирхогч\n")
                    f.write("- Battery storage шийдэл судлах хүн\n")
                    f.write("- Ухаалаг эрчим хүчний бүтээгдэхүүн, технологи хайж буй бизнес\n")
                    f.write("- Эрчим хүчний салбарт шинэ нийлүүлэгч, түнш хайж буй хүн\n\n")

                elif "SIAL" in expo_name:
                    f.write("#### Аяллын тухай\n\n")
                    f.write("SIAL Shanghai Expo нь хүнсний бизнесээ тэлэх, олон улсын хүнсний брэндүүд, бүтээгдэхүүн, нийлүүлэгчидтэй танилцах боломжтой үзэсгэлэн гэж илэрсэн.\n\n")

                    f.write("#### Хэнд тохиромжтой вэ?\n\n")
                    f.write("- Хүнсний бизнес эрхлэгч\n")
                    f.write("- Импортын хүнсний бүтээгдэхүүн хайж буй хүн\n")
                    f.write("- Олон улсын хүнсний брэнд судлах бизнес\n")
                    f.write("- Шинэ хүнсний бүтээгдэхүүн Монголд нэвтрүүлэхээр төлөвлөж буй хүн\n\n")

                f.write("#### Эх post-уудаас илэрсэн мэдээлэл\n\n")
                write_bullets(f, expo_posts, max_items=12)
                f.write("\n")

                dates = []
                for item in expo_posts:
                    dates.extend(extract_dates(item))

                dates = dedup_text_list(dates)

                if dates:
                    f.write("#### Илэрсэн огноо / цаг\n\n")
                    write_bullets(f, dates)
                    f.write("\n")

        # ====================================================
        # 6. Аяллын багцад багтах зүйлс
        # ====================================================

        f.write("## 6. Аяллын багцад багтах боломжтой зүйлс\n\n")
        f.write("Social post-ууд дээр дараах зүйлс аяллын багцад багтах боломжтой гэж дурдагдсан байна:\n\n")

        f.write("- Нислэгийн тийз\n")
        f.write("- Зочид буудал\n")
        f.write("- Дата SIM / eSIM\n")
        f.write("- Аяллын даатгал\n")
        f.write("- Мэргэжлийн орчуулагч\n")
        f.write("- Хөтөч\n")
        f.write("- Хөтөчийн зөвлөгөө\n")
        f.write("- Бизнесийн зөвлөгөө\n")
        f.write("- Тээвэр, логистикийн зөвлөгөө\n\n")

        f.write("### Эх post-уудаас илэрсэн мэдээлэл\n\n")
        write_bullets(f, knowledge["included_services"], max_items=15)
        f.write("\n")

        # ====================================================
        # 7. Бизнес дэмжлэг
        # ====================================================

        f.write("## 7. Бизнес дэмжлэг ба зөвлөгөө\n\n")
        f.write("Nomadabe Travel-ийн бизнес аяллын онцлог нь аяллын явцад бизнесийн зорилгод чиглэсэн зөвлөгөө, мэдээлэл өгөх байдлаар илэрч байна.\n\n")

        f.write("### Дурдагдсан зөвлөгөө, мэдлэгийн чиглэлүүд\n\n")
        f.write("- Бараа бүтээгдэхүүн сонгох арга\n")
        f.write("- Брэнд судлах арга\n")
        f.write("- Монголд бүтээгдэхүүн борлуулах боломжийн судалгаа\n")
        f.write("- Санхүүжилт босгох арга\n")
        f.write("- Банк болон банк бусын зээлийн шалгуур\n")
        f.write("- Сүлжээ дэлгүүрт бараа нийлүүлэх шаардлага\n")
        f.write("- Төлбөр тооцооны мэдээлэл\n")
        f.write("- Гэрээ хэлцэл байгуулах зөвлөгөө\n")
        f.write("- Маркетинг, төлөвлөлтийн загвар\n\n")

        f.write("### Эх post-уудаас илэрсэн мэдээлэл\n\n")
        write_bullets(f, knowledge["business_support"], max_items=18)
        f.write("\n")

        # ====================================================
        # 8. Логистик
        # ====================================================

        f.write("## 8. Тээвэр, логистикийн мэдээлэл\n\n")
        f.write("Social post-ууд дээр бараа бүтээгдэхүүнээ найдвартай каргогоор татах, тээвэр логистикийн зөвлөгөө авах боломжтой гэж дурдагдсан.\n\n")

        f.write("### Эх post-уудаас илэрсэн мэдээлэл\n\n")
        write_bullets(f, knowledge["logistics"], max_items=12)
        f.write("\n")

        # ====================================================
        # 9. Урамшуулал
        # ====================================================

        f.write("## 9. Урамшуулал ба онцгой санал\n\n")
        f.write("Social content дээр зарим бизнес аялалтай холбоотой буцаан олголт, early bird болон онцгой үнийн санал дурдагдсан байна.\n\n")

        f.write("### Эх post-уудаас илэрсэн мэдээлэл\n\n")
        write_bullets(f, knowledge["promotions"], max_items=12)
        f.write("\n")

        # ====================================================
        # 10. Чөлөөт аялал
        # ====================================================

        f.write("## 10. Чөлөөт аялал, амралт зугаалга\n\n")
        f.write("Nomadabe Travel нь бизнес аяллаас гадна хөтөлбөртэй амралт зугаалга болон чөлөөт аялал зохион байгуулдаг тухай мэдээлэл илэрсэн.\n\n")

        f.write("### Эх post-уудаас илэрсэн мэдээлэл\n\n")
        write_bullets(f, knowledge["leisure_travel"], max_items=10)
        f.write("\n")

        # ====================================================
        # 11. Салбарын чиг хандлага
        # ====================================================

        f.write("## 11. Аялал болон бизнесийн чиг хандлагын мэдээлэл\n\n")
        f.write("Social content дээр аяллын технологи, ухаалаг аяллын шийдэл, OEM/ODM, инноваци, салбарын шинэ чиг хандлага зэрэг мэдээллүүд дурдагдсан.\n\n")

        f.write("### Эх post-уудаас илэрсэн мэдээлэл\n\n")
        write_bullets(f, knowledge["travel_trends"], max_items=15)
        f.write("\n")

        # ====================================================
        # 12. Хэрэглэгчийн сэтгэгдэл
        # ====================================================

        f.write("## 12. Хэрэглэгч / аялагчдын сэтгэгдэл\n\n")
        f.write("Social content дээр үйлчилгээний талаар эерэг сэтгэгдэл илэрсэн бол chatbot-д trust signal болгон ашиглаж болно.\n\n")

        f.write("### Илэрсэн сэтгэгдлүүд\n\n")
        write_bullets(f, knowledge["testimonials"], max_items=10)
        f.write("\n")

        # ====================================================
        # 13. CTA
        # ====================================================

        f.write("## 13. Холбоо барих болон CTA мэдээлэл\n\n")
        f.write("Social post-ууд дээр дэлгэрэнгүй мэдээлэл авахын тулд comment бичих CTA олон удаа дурдагдсан байна.\n\n")

        f.write("### Илэрсэн CTA\n\n")
        write_bullets(f, knowledge["contact_cta"], max_items=15)
        f.write("\n")

        # ====================================================
        # 14. Chatbot FAQ
        # ====================================================

        f.write("## 14. Chatbot-д ашиглах FAQ\n\n")

        f.write("### Nomadabe Travel ямар аялал зохион байгуулдаг вэ?\n\n")
        f.write("Nomadabe Travel нь бизнес аялал, олон улсын үзэсгэлэн / expo аялал, хөтөлбөртэй амралт зугаалга болон чөлөөт аялал зохион байгуулдаг.\n\n")

        f.write("### Бизнес аяллын гол онцлог юу вэ?\n\n")
        f.write("Бизнес аялал нь зөвхөн аялал биш, харин бизнесийн зорилгод төвлөрсөн цогц үйлчилгээтэй. Үүнд бараа бүтээгдэхүүн сонгох, үйлдвэрлэгч судлах, санхүүжилт, маркетинг, гэрээ хэлцэл, тээвэр логистикийн зөвлөгөө зэрэг багтдаг.\n\n")

        f.write("### Canton Fair аялал хэнд тохиромжтой вэ?\n\n")
        f.write("Canton Fair аялал нь импортын бизнес эхлүүлэх, бизнесээ өргөжүүлэх, шинэ бараа бүтээгдэхүүн, тоног төхөөрөмж, брэнд, үйлдвэрлэгч хайж буй бизнес эрхлэгчдэд тохиромжтой.\n\n")

        f.write("### SNEC PV+ 2026 аялал хэнд тохиромжтой вэ?\n\n")
        f.write("SNEC PV+ 2026 аялал нь нарны эрчим хүч, battery storage, ухаалаг эрчим хүчний технологи, шинэ бүтээгдэхүүн, шинэ нийлүүлэгч судлах хүмүүст тохиромжтой.\n\n")

        f.write("### SIAL Shanghai Expo аялал хэнд тохиромжтой вэ?\n\n")
        f.write("SIAL Shanghai Expo аялал нь хүнсний бизнес эрхлэгч, импортын хүнсний бүтээгдэхүүн хайж буй хүн, шинэ хүнсний брэнд болон нийлүүлэгч судлах бизнесүүдэд тохиромжтой.\n\n")

        f.write("### Аяллын багцад юу багтаж болох вэ?\n\n")
        f.write("Social content дээр нислэгийн тийз, зочид буудал, дата SIM/eSIM, аяллын даатгал, мэргэжлийн орчуулагч, хөтөч, бизнес зөвлөгөө, тээвэр логистикийн зөвлөгөө багтах боломжтой гэж дурдагдсан.\n\n")

        f.write("### Дэлгэрэнгүй мэдээлэл яаж авах вэ?\n\n")
        f.write("Зарим post дээр дэлгэрэнгүй мэдээлэл авахын тулд “8” эсвэл “9” гэж бичих CTA дурдагдсан. Яг аль аялал, event-ээс хамааран CTA код өөр байж болно.\n\n")

        # ====================================================
        # 15. AI Agent instructions
        # ====================================================

        f.write("## 15. AI Agent-д зориулсан хариулах заавар\n\n")

        f.write("### Ерөнхий зарчим\n\n")
        f.write("- Хариулахдаа Nomadabe Travel-ийг бизнес аялал, expo аялал, хөтөлбөртэй амралт зугаалга болон чөлөөт аялал зохион байгуулдаг аяллын компани гэж тайлбарлана.\n")
        f.write("- Хэрэглэгч бизнес аяллын талаар асуувал Canton Fair, SNEC PV+, SIAL Shanghai Expo зэрэг social content дээр дурдагдсан event-үүдийг жишээ болгон тайлбарлана.\n")
        f.write("- Аяллын багцад багтах зүйлсийг хэлэхдээ social content дээр дурдагдсан нислэг, буудал, eSIM/data SIM, даатгал, орчуулагч, хөтөч, зөвлөгөө зэрэг мэдээллийг ашиглана.\n")
        f.write("- Үнийн мэдээлэл raw post-оос тодорхой гараагүй бол таамаглаж үнэ зохиохгүй.\n")
        f.write("- Огноо, суудал, үнэ, хөтөлбөр өөрчлөгдөж болох тул хэрэглэгчийг шууд холбоо барих эсвэл дэлгэрэнгүй мэдээлэл авах CTA руу чиглүүлнэ.\n\n")

        f.write("### Хариултын tone\n\n")
        f.write("- Эелдэг\n")
        f.write("- Мэргэжлийн\n")
        f.write("- Тодорхой\n")
        f.write("- Борлуулалтын өнгө аястай боловч хэт шахсан биш\n")
        f.write("- Аяллын зорилго, хэнд тохиромжтой, юу багтахыг ойлгомжтой тайлбарлана\n\n")

        # ====================================================
        # 16. Raw useful posts
        # ====================================================

        f.write("## 16. Ашигтай raw эх мэдээлэл\n\n")
        f.write("Доорх нь knowledge extraction-д ашиглагдсан raw social text-үүд юм.\n\n")

        if not knowledge["raw_useful_posts"]:
            f.write("- Ашигтай raw post илрээгүй.\n")
        else:
            for i, post in enumerate(knowledge["raw_useful_posts"], start=1):
                f.write(f"### Source Text {i}\n\n")
                f.write(f"- Source type: {post.get('source_type', '')}\n")
                f.write(f"- Source URL: {post.get('source_url', '')}\n\n")
                f.write(post.get("text", ""))
                f.write("\n\n---\n\n")

    print(f"Markdown saved: {OUTPUT_MD}")


# ============================================================
# 11. Main
# ============================================================

def main() -> None:
    all_posts = []

    with sync_playwright() as p:
        browser = p.chromium.launch(
            headless=False,
            slow_mo=300,
        )

        page = browser.new_page(
            viewport={"width": 1400, "height": 900}
        )

        for url in URLS:
            posts = crawl_public_page(page, url)
            all_posts.extend(posts)

        browser.close()

    all_posts = remove_duplicates(all_posts)

    save_csv(all_posts)
    save_structured_markdown(all_posts)

    print("\nDone.")
    print(f"Total extracted text blocks: {len(all_posts)}")
    print(f"CSV: {OUTPUT_CSV}")
    print(f"Knowledge MD: {OUTPUT_MD}")


if __name__ == "__main__":
    main()