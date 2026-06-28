# Шинэ CSV дээр model ажиллуулах

Энэ workspace дээр `run_model_on_new_csv.py` script нэмсэн.

## 1. Package суулгах

```powershell
python -m pip install -r requirements-inference.txt
```

Таны одоогийн local Python дээр `torch` байхгүй байна. Хэрвээ install удаан эсвэл алдаа өгвөл Colab GPU дээр энэ script-ийг ажиллуулах нь илүү амар.

## 2. Эхлээд CSV/prompt шалгах

```powershell
python .\run_model_on_new_csv.py --input-csv ".\model-20260622T102845Z-3-001\model\adapter\2026 01 - 05 задгай гоо сайхан.csv" --task beauty --max-rows 5 --dry-run
```

## 3. Гоо сайхны CSV дээр prediction хийх

Эхлээд 20 мөр дээр тест:

```powershell
python .\run_model_on_new_csv.py --input-csv ".\model-20260622T102845Z-3-001\model\adapter\2026 01 - 05 задгай гоо сайхан.csv" --task beauty --max-rows 20 --batch-size 1
```

Бүтэн дата дээр:

```powershell
python .\run_model_on_new_csv.py --input-csv "C:\path\to\new_data.csv" --task beauty --batch-size 1 --output-csv ".\new_data_predictions.csv"
```

Output баганууд:

- `llm_is_beauty`
- `llm_predicted_brand`
- `llm_predicted_category`
- `llm_predicted_subcategory`
- `llm_reason`
- `llm_raw_output`

## 4. Beer brand model шиг ажиллуулах бол

```powershell
python .\run_model_on_new_csv.py --input-csv ".\beer_data_6.16.csv" --task beer_brand --max-rows 50 --batch-size 1
```

## Санамж

Анх удаа ажиллуулахад base model `Qwen/Qwen2.5-0.5B-Instruct`-ийг Hugging Face-ээс татах хэрэгтэй байж магадгүй. Интернэтгүй эсвэл model cache-д байхгүй үед `--local-files-only` бүү ашигла.
