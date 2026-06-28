# -*- coding: utf-8 -*-
"""Run the local Qwen LoRA adapter on a new customs CSV.

Default mode is for the beauty classifier notebook found in this workspace.
Use --task beer_brand when you want the beer brand extraction prompt instead.
"""

from __future__ import annotations

import argparse
import json
import re
import sys
import warnings
from pathlib import Path
from typing import Any, Iterable

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
if hasattr(sys.stderr, "reconfigure"):
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")


DEFAULT_BASE_MODEL = "Qwen/Qwen2.5-0.5B-Instruct"
DEFAULT_ADAPTER_DIR = Path("model-20260622T102845Z-3-001") / "model" / "adapter"

BEAUTY_OUTPUT_COLUMNS = [
    "llm_is_beauty",
    "llm_predicted_brand",
    "llm_predicted_category",
    "llm_predicted_subcategory",
    "llm_reason",
    "llm_raw_output",
]

BEAUTY_TARGET_COLUMNS = [
    "Ангилал",
    "Брэнд",
    "Дэд ангилал",
    "Category",
    "Нэр төрөл/Нойтон, Хуурай, Ариун цэврийн цаас/",
]

TEXT_COLUMNS = [
    "Барааны нэр",
    "Марк",
    "Гадаад нэр",
    "BBB",
    "Зориулалт",
    "Ангилал",
    "Дэд ангилал",
    "Төрөл",
    "Category",
    "Country",
    "Гарал үүсэл",
    "Илгээгч улс",
    "Үйлдвэрлэсэн компани",
    "Хүлээн авагч",
]

BEAUTY_SYSTEM_PROMPT = (
    "Чи импортын барааны текстээс гоо сайхны бүтээгдэхүүний "
    "брэнд, ангилал, дэд ангиллыг зөвхөн JSON хэлбэрээр гаргадаг туслах."
)

BEER_SYSTEM_PROMPT = """You are a beer product brand extraction model for customs/import data.
Return ONLY the real consumer brand name.
Do not return manufacturer/company names, importer names, country/region names, beer style, packaging, flavor, size, alcohol percentage, or product category.
If the brand cannot be identified, return UNKNOWN.
No explanation. No JSON. Only one brand string."""

GENERIC_BRAND_SYSTEM_PROMPT = """You extract product brand names from customs/import CSV rows.
Return ONLY the real consumer brand name.
Do not return manufacturer/company names, importer names, country names, category names, packaging, size, or descriptive words.
If the brand cannot be identified, return UNKNOWN.
No explanation. No JSON. Only one brand string."""


def fail_missing_package(import_name: str, pip_name: str | None = None) -> None:
    package = pip_name or import_name
    raise SystemExit(
        f"Missing Python package: {import_name}\n"
        f"Install dependencies first:\n"
        f"  python -m pip install -r requirements-inference.txt\n"
        f"Or install just this package:\n"
        f"  python -m pip install {package}"
    )


def import_pandas():
    try:
        import pandas as pd
    except ModuleNotFoundError:
        fail_missing_package("pandas")
    return pd


def clean_text(value: Any) -> str:
    text = str(value or "").strip()
    text = re.sub(r"\s+", " ", text)
    return text


def first_existing_column(row: Any, names: Iterable[str]) -> str:
    for name in names:
        if name in row.index:
            value = clean_text(row.get(name, ""))
            if value and value.lower() not in {"nan", "none", "null"}:
                return value
    return ""


def row_to_text(row: Any, columns: list[str]) -> str:
    parts = []
    for col in columns:
        value = first_existing_column(row, [col])
        if value:
            parts.append(f"{col}: {value}")
    return "\n".join(parts)


def read_csv_safely(path: Path, nrows: int | None = None):
    pd = import_pandas()
    encodings = ["utf-8-sig", "utf-8", "cp1251", "latin1"]
    last_error: Exception | None = None

    for encoding in encodings:
        try:
            return pd.read_csv(
                path,
                encoding=encoding,
                sep=None,
                engine="python",
                dtype=str,
                keep_default_na=False,
                nrows=nrows,
            )
        except Exception as exc:  # pragma: no cover - depends on input file
            last_error = exc

    raise RuntimeError(f"Could not read CSV: {path}\nLast error: {last_error}")


def infer_base_model(adapter_dir: Path, fallback: str = DEFAULT_BASE_MODEL) -> str:
    config_path = adapter_dir / "adapter_config.json"
    if not config_path.exists():
        return fallback

    try:
        config = json.loads(config_path.read_text(encoding="utf-8"))
    except Exception:
        return fallback

    return clean_text(config.get("base_model_name_or_path")) or fallback


def make_chat_text(tokenizer: Any, system_prompt: str, user_prompt: str) -> str:
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]

    try:
        return tokenizer.apply_chat_template(
            messages,
            tokenize=False,
            add_generation_prompt=True,
        )
    except Exception:
        return (
            f"<|im_start|>system\n{system_prompt}<|im_end|>\n"
            f"<|im_start|>user\n{user_prompt}<|im_end|>\n"
            "<|im_start|>assistant\n"
        )


def build_beauty_prompt(row: Any) -> str:
    name = first_existing_column(row, ["Барааны нэр"])
    mark = first_existing_column(row, ["Марк"])
    foreign = first_existing_column(row, ["Гадаад нэр"])
    code = first_existing_column(row, ["Барааны код", "Код2", "Код3", "Код4", "Код6"])

    return f"""
Чи beauty product classifier. Доорх барааг ангил.

Барааны нэр: {name}
Марк: {mark}
Гадаад нэр: {foreign}
Барааны код: {code}

Зөвхөн доорх JSON format-аар хариул. Өөр текст, markdown, input copy хийхгүй.

JSON format:
{{"is_beauty":"yes/no","brand":"","category":"","subcategory":"","reason":""}}

Дүрэм:
- Гоо сайхны бүтээгдэхүүн бол is_beauty="yes".
- Гоо сайхны биш бол is_beauty="no", brand/category/subcategory="".
- Брэндийг зөвхөн Марк, Барааны нэр, Гадаад нэр доторх бодит product brand-аас ав.
- Үйлдвэрлэгч компани, улс, importer company-г brand болгож болохгүй.
- Мэдэхгүй бол хоосон string "" тавь.
- Category жишээ: Үс арчилгаа, Нүүр арчилгаа, Бие арчилгаа, Гар арчилгаа, Амны хөндий, Үнэртэн, Нарны тос, Нүүр будалт, Цэвэрлэгээ.
- Subcategory жишээ: Шампунь, Ангижруулагч, Серум, Нүүрний тос, Гар тос, Body wash, Саван, Шүдний оо, Dental floss, Маск.
""".strip()


def build_brand_prompt(row: Any, columns: list[str]) -> str:
    text = row_to_text(row, columns)
    return f"Extract the product brand from this customs/import row:\n\n{text}"


def looks_like_invalid_brand(value: Any) -> bool:
    text = clean_text(value)
    if not text:
        return True
    bad = {
        "-",
        ".",
        "n/a",
        "na",
        "none",
        "null",
        "no brand",
        "брэндгүй",
        "хятад",
        "china",
        "mongolia",
        "korea",
        "japan",
        "usa",
    }
    return text.lower() in bad or len(text) > 60


def keyword_fallback_beauty(row: Any) -> dict[str, str]:
    name = first_existing_column(row, ["Барааны нэр"])
    mark = first_existing_column(row, ["Марк"])
    foreign = first_existing_column(row, ["Гадаад нэр"])
    text = f"{name} {mark} {foreign}".lower()

    beauty_keywords = {
        "Шампунь": ["shampoo", "шампун"],
        "Ангижруулагч": ["conditioner", "ангиж"],
        "Үсний тос/серум": ["hair oil", "hair serum", "serum", "үсний тос"],
        "Нүүрний тос": ["face cream", "cream", "нүүрний тос", "moistur"],
        "Серум": ["serum", "эссэнс", "essence"],
        "Нүүр цэвэрлэгээ": ["cleanser", "cleansing", "мицел", "micellar", "foam"],
        "Маск": ["mask", "маск"],
        "Гар тос": ["hand cream", "гар тос"],
        "Биеийн тос": ["body lotion", "body cream", "lotion"],
        "Body wash": ["body wash", "shower gel", "душ", "бие угаагч"],
        "Саван": ["soap", "саван"],
        "Шүдний оо": ["toothpaste", "шүдний оо"],
        "Dental floss": ["floss", "dental floss"],
        "Үнэртэн": ["perfume", "parfum", "eau de", "үнэртэн"],
        "Нарны тос": ["sunscreen", "sun cream", "spf"],
        "Нүүр будалт": ["lipstick", "mascara", "foundation", "bb cream", "cushion", "eyeliner"],
        "Deodorant": ["deodorant", "roll on", "антиперспирант"],
    }
    category_map = {
        "Шампунь": "Үс арчилгаа",
        "Ангижруулагч": "Үс арчилгаа",
        "Үсний тос/серум": "Үс арчилгаа",
        "Нүүрний тос": "Нүүр арчилгаа",
        "Серум": "Нүүр арчилгаа",
        "Нүүр цэвэрлэгээ": "Нүүр арчилгаа",
        "Маск": "Нүүр арчилгаа",
        "Гар тос": "Гар арчилгаа",
        "Биеийн тос": "Бие арчилгаа",
        "Body wash": "Бие арчилгаа",
        "Саван": "Бие арчилгаа",
        "Шүдний оо": "Амны хөндий",
        "Dental floss": "Амны хөндий",
        "Үнэртэн": "Үнэртэн",
        "Нарны тос": "Нарны тос",
        "Нүүр будалт": "Нүүр будалт",
        "Deodorant": "Бие арчилгаа",
    }

    subcategory = ""
    for candidate, keywords in beauty_keywords.items():
        if any(keyword in text for keyword in keywords):
            subcategory = candidate
            break

    if not subcategory:
        return {
            "is_beauty": "no",
            "brand": "",
            "category": "",
            "subcategory": "",
            "reason": "keyword fallback: beauty keyword олдсонгүй",
        }

    brand = ""
    if not looks_like_invalid_brand(mark):
        brand = mark
    else:
        candidate_text = foreign or name
        match = re.match(r"([A-Za-z][A-Za-z0-9&'\-. ]{1,30})", candidate_text)
        if match:
            brand = match.group(1).strip(" -.,")
        if looks_like_invalid_brand(brand):
            brand = ""

    return {
        "is_beauty": "yes",
        "brand": brand,
        "category": category_map.get(subcategory, ""),
        "subcategory": subcategory,
        "reason": "keyword fallback",
    }


def parse_beauty_output(text: str, row: Any | None = None) -> dict[str, str]:
    parsed = {
        "is_beauty": "",
        "brand": "",
        "category": "",
        "subcategory": "",
        "reason": "",
    }

    original = clean_text(text)
    cleaned = original.replace("```json", "").replace("```", "").strip()
    candidates = re.findall(r"\{.*?\}", cleaned, flags=re.DOTALL)

    data = None
    for candidate in reversed(candidates):
        try:
            maybe_data = json.loads(candidate)
        except Exception:
            continue
        data = maybe_data
        if any(key in maybe_data for key in ["is_beauty", "brand", "category", "subcategory"]):
            break

    if data is None:
        if row is not None:
            fallback = keyword_fallback_beauty(row)
            fallback["reason"] = "model JSON parse failed; " + fallback.get("reason", "")
            return fallback
        parsed["reason"] = original[:300]
        return parsed

    parsed["is_beauty"] = clean_text(data.get("is_beauty", ""))
    parsed["brand"] = clean_text(data.get("brand", ""))
    parsed["category"] = clean_text(data.get("category", ""))
    parsed["subcategory"] = clean_text(data.get("subcategory", ""))
    parsed["reason"] = clean_text(data.get("reason", ""))

    copied_input_keys = ["Барааны нэр", "Марк", "Гадаад нэр", "Барааны код"]
    no_prediction = not any(
        [parsed["is_beauty"], parsed["brand"], parsed["category"], parsed["subcategory"]]
    )
    if any(key in data for key in copied_input_keys) and no_prediction and row is not None:
        fallback = keyword_fallback_beauty(row)
        fallback["reason"] = "model copied input; " + fallback.get("reason", "")
        return fallback

    if not parsed["is_beauty"] and (
        parsed["brand"] or parsed["category"] or parsed["subcategory"]
    ):
        parsed["is_beauty"] = "yes"

    if parsed["is_beauty"].lower() in {"no", "false", "0"}:
        parsed["brand"] = ""
        parsed["category"] = ""
        parsed["subcategory"] = ""

    return parsed


def parse_brand_output(text: str) -> str:
    cleaned = clean_text(text)
    cleaned = cleaned.replace("```", "").strip()

    try:
        data = json.loads(cleaned)
        if isinstance(data, dict):
            cleaned = clean_text(data.get("brand") or data.get("Брэнд") or "")
    except Exception:
        pass

    cleaned = re.split(r"[\n\r]", cleaned)[0]
    cleaned = cleaned.strip(" \"'`.,;:")
    if cleaned.lower() in {"unknown", "unk", "none", "null", "n/a", "na"}:
        return ""
    return cleaned


def row_has_empty_targets(row: Any, task: str) -> bool:
    if task == "beauty":
        columns = BEAUTY_TARGET_COLUMNS
    else:
        columns = ["Брэнд"]

    for col in columns:
        if col in row.index and not clean_text(row.get(col, "")):
            return True
    return False


def load_model_and_tokenizer(
    adapter_dir: Path,
    base_model_name: str,
    local_files_only: bool,
):
    try:
        import torch
    except ModuleNotFoundError:
        fail_missing_package("torch")

    try:
        from transformers import AutoModelForCausalLM, AutoTokenizer
    except ModuleNotFoundError:
        fail_missing_package("transformers")

    try:
        from peft import PeftModel
    except ModuleNotFoundError:
        fail_missing_package("peft")

    device = "cuda" if torch.cuda.is_available() else "cpu"
    dtype = torch.float16 if device == "cuda" else torch.float32

    print(f"Device: {device}")
    print(f"Base model: {base_model_name}")
    print(f"Adapter dir: {adapter_dir}")

    tokenizer_kwargs = {
        "trust_remote_code": True,
        "local_files_only": local_files_only,
    }
    try:
        tokenizer = AutoTokenizer.from_pretrained(adapter_dir, **tokenizer_kwargs)
    except Exception as exc:
        warnings.warn(f"Adapter tokenizer уншиж чадсангүй, base tokenizer ашиглана: {exc}")
        tokenizer = AutoTokenizer.from_pretrained(base_model_name, **tokenizer_kwargs)

    chat_template_path = adapter_dir / "chat_template.jinja"
    if chat_template_path.exists():
        tokenizer.chat_template = chat_template_path.read_text(encoding="utf-8")

    if tokenizer.pad_token is None:
        tokenizer.pad_token = tokenizer.eos_token
    tokenizer.padding_side = "left"

    model_kwargs: dict[str, Any] = {
        "trust_remote_code": True,
        "torch_dtype": dtype,
        "local_files_only": local_files_only,
    }
    if device == "cuda":
        model_kwargs["device_map"] = "auto"

    base_model = AutoModelForCausalLM.from_pretrained(base_model_name, **model_kwargs)
    if device == "cpu":
        base_model.to(device)

    model = PeftModel.from_pretrained(
        base_model,
        adapter_dir,
        local_files_only=local_files_only,
    )
    model.eval()
    return model, tokenizer


def predict_batch(
    model: Any,
    tokenizer: Any,
    task: str,
    rows: list[Any],
    text_columns: list[str],
    max_input_length: int,
    max_new_tokens: int,
    blank_non_beauty: bool,
) -> list[dict[str, str]]:
    import torch

    if task == "beauty":
        system_prompt = BEAUTY_SYSTEM_PROMPT
        prompts = [build_beauty_prompt(row) for row in rows]
    elif task == "beer_brand":
        system_prompt = BEER_SYSTEM_PROMPT
        prompts = [build_brand_prompt(row, text_columns) for row in rows]
    else:
        system_prompt = GENERIC_BRAND_SYSTEM_PROMPT
        prompts = [build_brand_prompt(row, text_columns) for row in rows]

    chat_texts = [make_chat_text(tokenizer, system_prompt, prompt) for prompt in prompts]

    inputs = tokenizer(
        chat_texts,
        return_tensors="pt",
        padding=True,
        truncation=True,
        max_length=max_input_length,
    )
    model_device = next(model.parameters()).device
    inputs = {key: value.to(model_device) for key, value in inputs.items()}

    with torch.inference_mode():
        generated = model.generate(
            **inputs,
            max_new_tokens=max_new_tokens,
            do_sample=False,
            repetition_penalty=1.05,
            pad_token_id=tokenizer.pad_token_id,
            eos_token_id=tokenizer.eos_token_id,
        )

    prompt_len = inputs["input_ids"].shape[1]
    results = []
    for output_ids, row in zip(generated, rows):
        new_tokens = output_ids[prompt_len:]
        decoded = tokenizer.decode(new_tokens, skip_special_tokens=True).strip()

        if task == "beauty":
            parsed = parse_beauty_output(decoded, row=row)
            if blank_non_beauty and parsed.get("is_beauty", "").lower() in {"no", "false", "0"}:
                parsed["brand"] = ""
                parsed["category"] = ""
                parsed["subcategory"] = ""
            parsed["raw_model_output"] = decoded
        else:
            parsed = {
                "brand": parse_brand_output(decoded),
                "raw_model_output": decoded,
            }
        results.append(parsed)

    return results


def output_path_for(input_csv: Path, task: str) -> Path:
    return input_csv.with_name(f"{input_csv.stem}_{task}_predictions.csv")


def save_output_csv(df: Any, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    df.to_csv(path, index=False, encoding="utf-8-sig")


def parse_text_columns(value: str, df_columns: list[str]) -> list[str]:
    if value.strip():
        requested = [item.strip() for item in value.split("|") if item.strip()]
    else:
        requested = TEXT_COLUMNS

    available = [col for col in requested if col in df_columns]
    if available:
        return available

    fallback = [col for col in df_columns if col and not col.startswith("Column")]
    return fallback[:12]


def print_dry_run(df: Any, task: str, text_columns: list[str]) -> None:
    print(f"CSV shape: {df.shape}")
    print("Columns:")
    for index, col in enumerate(df.columns):
        print(f"  {index}: {col}")

    if len(df) == 0:
        print("CSV хоосон байна.")
        return

    first_row = df.iloc[0]
    if task == "beauty":
        prompt = build_beauty_prompt(first_row)
    else:
        prompt = build_brand_prompt(first_row, text_columns)

    print("\nSelected text columns:")
    for col in text_columns:
        print(f"  - {col}")

    print("\nFirst prompt preview:")
    print(prompt[:2500])


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Run local Qwen LoRA adapter predictions on a new CSV."
    )
    parser.add_argument("--input-csv", required=True, help="Path to the new CSV file.")
    parser.add_argument(
        "--adapter-dir",
        default=str(DEFAULT_ADAPTER_DIR),
        help="Folder containing adapter_config.json and adapter_model.safetensors.",
    )
    parser.add_argument(
        "--base-model",
        default="",
        help="Override base model. Default is read from adapter_config.json.",
    )
    parser.add_argument(
        "--task",
        choices=["beauty", "beer_brand", "brand"],
        default="beauty",
        help="Prediction prompt/output mode.",
    )
    parser.add_argument(
        "--output-csv",
        default="",
        help="Output CSV path. Default: input filename plus _<task>_predictions.csv.",
    )
    parser.add_argument(
        "--text-columns",
        default="",
        help="Pipe-separated input columns for brand tasks. Empty means auto/default.",
    )
    parser.add_argument("--max-rows", type=int, default=None, help="Read only first N rows.")
    parser.add_argument("--batch-size", type=int, default=1, help="Inference batch size.")
    parser.add_argument("--max-input-length", type=int, default=1024)
    parser.add_argument("--max-new-tokens", type=int, default=220)
    parser.add_argument(
        "--only-empty-targets",
        action="store_true",
        help="Run only rows with empty target columns.",
    )
    parser.add_argument(
        "--blank-non-beauty",
        action="store_true",
        help="For --task beauty, blank brand/category/subcategory when is_beauty is no.",
    )
    parser.add_argument(
        "--local-files-only",
        action="store_true",
        help="Do not download the base model/tokenizer. Requires local Hugging Face cache.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Read CSV and show prompt preview without loading the model.",
    )
    parser.add_argument(
        "--checkpoint-every",
        type=int,
        default=1000,
        help="Save partial output every N predicted rows. Use 0 to disable.",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv or sys.argv[1:])

    input_csv = Path(args.input_csv)
    adapter_dir = Path(args.adapter_dir)
    if not input_csv.exists():
        raise SystemExit(f"CSV not found: {input_csv}")
    if not adapter_dir.exists():
        raise SystemExit(f"Adapter folder not found: {adapter_dir}")
    for required_file in ["adapter_config.json", "adapter_model.safetensors"]:
        if not (adapter_dir / required_file).exists():
            raise SystemExit(f"Adapter file missing: {adapter_dir / required_file}")

    df = read_csv_safely(input_csv, nrows=args.max_rows)
    text_columns = parse_text_columns(args.text_columns, list(df.columns))
    output_csv = Path(args.output_csv) if args.output_csv else output_path_for(input_csv, args.task)

    if args.dry_run:
        print_dry_run(df, args.task, text_columns)
        print(f"\nOutput would be: {output_csv}")
        return 0

    base_model = clean_text(args.base_model) or infer_base_model(adapter_dir)
    model, tokenizer = load_model_and_tokenizer(
        adapter_dir=adapter_dir,
        base_model_name=base_model,
        local_files_only=args.local_files_only,
    )

    if args.task == "beauty":
        for col in BEAUTY_OUTPUT_COLUMNS:
            if col not in df.columns:
                df[col] = ""
    else:
        for col in ["llm_predicted_brand", "llm_raw_output"]:
            if col not in df.columns:
                df[col] = ""

    if args.only_empty_targets:
        target_indices = [
            index for index, row in df.iterrows() if row_has_empty_targets(row, args.task)
        ]
    else:
        target_indices = list(df.index)

    print(f"CSV rows loaded: {len(df)}")
    print(f"Rows to predict: {len(target_indices)}")
    print(f"Output CSV: {output_csv}")

    predicted_count = 0
    for start in range(0, len(target_indices), args.batch_size):
        batch_indices = target_indices[start : start + args.batch_size]
        rows = [df.loc[index] for index in batch_indices]
        predictions = predict_batch(
            model=model,
            tokenizer=tokenizer,
            task=args.task,
            rows=rows,
            text_columns=text_columns,
            max_input_length=args.max_input_length,
            max_new_tokens=args.max_new_tokens,
            blank_non_beauty=args.blank_non_beauty,
        )

        for index, pred in zip(batch_indices, predictions):
            if args.task == "beauty":
                df.at[index, "llm_is_beauty"] = pred.get("is_beauty", "")
                df.at[index, "llm_predicted_brand"] = pred.get("brand", "")
                df.at[index, "llm_predicted_category"] = pred.get("category", "")
                df.at[index, "llm_predicted_subcategory"] = pred.get("subcategory", "")
                df.at[index, "llm_reason"] = pred.get("reason", "")
                df.at[index, "llm_raw_output"] = pred.get("raw_model_output", "")
            else:
                df.at[index, "llm_predicted_brand"] = pred.get("brand", "")
                df.at[index, "llm_raw_output"] = pred.get("raw_model_output", "")

        predicted_count += len(batch_indices)
        print(f"Predicted {predicted_count}/{len(target_indices)}", flush=True)
        if args.checkpoint_every and predicted_count % args.checkpoint_every == 0:
            save_output_csv(df, output_csv)
            print(f"Checkpoint saved: {output_csv}")

    save_output_csv(df, output_csv)
    print(f"Done. Saved: {output_csv}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
