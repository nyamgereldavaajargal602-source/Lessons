from playwright.sync_api import sync_playwright
from bs4 import BeautifulSoup
from urllib.parse import urljoin, urlparse
import os
import json
import time


# =========================
# 1. Crawl хийх үндсэн тохиргоо
# =========================

BASE_URL = "https://www.artisyhub.mn/home"
DOMAIN_LIST = ["www.artisyhub.mn", "artisyhub.mn"]

OUTPUT_DIR = "output_artisyhub"

MAX_PAGES = 80          # Хэт олон page crawl хийхээс хамгаална
WAIT_TIME = 3000        # JS content ачаалагдахыг 3 секунд хүлээнэ


# =========================
# 2. Internal link шалгах
# =========================

def is_internal_link(url: str) -> bool:
    """
    Зөвхөн artisyhub.mn доторх link мөн эсэхийг шалгана.
    """
    parsed = urlparse(url)
    return parsed.netloc in DOMAIN_LIST


def clean_url(url: str) -> str:
    """
    URL дээрх #section, trailing slash гэх мэтийг цэвэрлэнэ.
    """
    parsed = urlparse(url)

    cleaned = parsed._replace(fragment="").geturl()

    # Давхар slash issue биш, харин төгсгөлийн /-ийг жигд болгоно
    if cleaned.endswith("/") and cleaned != "https://www.artisyhub.mn/":
        cleaned = cleaned.rstrip("/")

    return cleaned


# =========================
# 3. HTML-ээс цэвэр text авах
# =========================

def extract_clean_text(html: str) -> str:
    """
    HTML-ээс script/style/nav/footer гэх мэт хэрэггүй хэсгийг аваад
    цэвэр text гаргана.
    """
    soup = BeautifulSoup(html, "html.parser")

    # Хэрэггүй tag-уудыг устгана
    for tag in soup([
        "script",
        "style",
        "noscript",
        "svg",
        "canvas",
        "iframe"
    ]):
        tag.decompose()

    # Header/footer/nav их давтагддаг тул боломжтой бол устгана
    for tag in soup.find_all(["nav", "header", "footer"]):
        tag.decompose()

    text = soup.get_text(separator="\n", strip=True)

    # Давхардсан хоосон мөр цэвэрлэх
    lines = [line.strip() for line in text.splitlines() if line.strip()]

    # Давхардсан мөрүүдийг арай цэвэрхэн болгох
    cleaned_lines = []
    seen = set()

    for line in lines:
        if line not in seen:
            cleaned_lines.append(line)
            seen.add(line)

    return "\n".join(cleaned_lines)


# =========================
# 4. Link extract хийх
# =========================

def extract_links(page, current_url: str) -> list[str]:
    """
    Page дээрх бүх internal links-ийг авна.
    """
    links = page.eval_on_selector_all(
        "a",
        "els => els.map(a => a.href).filter(Boolean)"
    )

    cleaned_links = []

    for link in links:
        absolute_url = urljoin(current_url, link)
        absolute_url = clean_url(absolute_url)

        if is_internal_link(absolute_url):
            cleaned_links.append(absolute_url)

    return list(set(cleaned_links))


# =========================
# 5. Page crawl хийх
# =========================

def crawl_site():
    os.makedirs(OUTPUT_DIR, exist_ok=True)

    visited = set()
    queue = [BASE_URL]
    results = []

    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)

        page = browser.new_page(
            viewport={"width": 1366, "height": 768}
        )

        while queue and len(visited) < MAX_PAGES:
            url = queue.pop(0)

            if url in visited:
                continue

            print(f"Crawling: {url}")

            try:
                page.goto(url, wait_until="networkidle", timeout=60000)
                page.wait_for_timeout(WAIT_TIME)

                # Lazy load content ачаалах гэж хэд хэдэн удаа scroll хийнэ
                for _ in range(4):
                    page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
                    page.wait_for_timeout(1000)

                title = page.title()
                html = page.content()
                text = extract_clean_text(html)
                links = extract_links(page, url)

                visited.add(url)

                results.append({
                    "url": url,
                    "title": title,
                    "text": text,
                    "links": links
                })

                # Шинэ internal links-ийг queue-д нэмнэ
                for link in links:
                    if link not in visited and link not in queue:
                        queue.append(link)

            except Exception as e:
                print(f"Failed: {url}")
                print(f"Reason: {e}")

        browser.close()

    return results


# =========================
# 6. JSON + Markdown хадгалах
# =========================

def save_outputs(results):
    """
    JSON болон Markdown source document болгож хадгална.
    """
    json_path = os.path.join(OUTPUT_DIR, "artisyhub_crawl_raw.json")
    md_path = os.path.join(OUTPUT_DIR, "artisyhub_crawl_markdown.md")

    # Raw JSON хадгалах
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(results, f, ensure_ascii=False, indent=2)

    # Markdown source document хадгалах
    with open(md_path, "w", encoding="utf-8") as f:
        f.write("# ArtisyHub Website Crawl Raw Knowledge Source\n\n")
        f.write(f"Source: {BASE_URL}\n\n")
        f.write(f"Total pages crawled: {len(results)}\n\n")
        f.write("---\n\n")

        for i, item in enumerate(results, start=1):
            f.write(f"# Page {i}: {item['title']}\n\n")
            f.write(f"URL: {item['url']}\n\n")

            if item["text"].strip():
                f.write(item["text"])
            else:
                f.write("[No visible text extracted]")

            f.write("\n\n## Links found on this page\n\n")

            for link in item["links"]:
                f.write(f"- {link}\n")

            f.write("\n\n---\n\n")

    print("\nDone.")
    print(f"JSON saved: {json_path}")
    print(f"Markdown saved: {md_path}")


# =========================
# 7. Main
# =========================

if __name__ == "__main__":
    results = crawl_site()
    save_outputs(results)