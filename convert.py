import csv
from pathlib import Path

PROJECT_DIR = Path(__file__).resolve().parent
SOURCE_DIR = PROJECT_DIR / "import" / "ml-1m"
TARGET_DIR = PROJECT_DIR / "import"


def convert_file(source_name: str, target_name: str, header: list[str], expected_columns: int) -> int:
    source = SOURCE_DIR / source_name
    target = TARGET_DIR / target_name

    if not source.is_file():
        raise FileNotFoundError(f"Не знайдено вихідний файл: {source}")

    TARGET_DIR.mkdir(parents=True, exist_ok=True)
    count = 0

    with source.open("r", encoding="latin-1", newline="") as input_file, \
         target.open("w", encoding="utf-8", newline="") as output_file:
        writer = csv.writer(output_file, delimiter=",")
        writer.writerow(header)

        for line_number, line in enumerate(input_file, start=1):
            if not line.strip():
                continue

            parts = line.rstrip("\r\n").split("::")
            if len(parts) != expected_columns:
                raise ValueError(
                    f"{source_name}, рядок {line_number}: "
                    f"очікувалося {expected_columns} полів, отримано {len(parts)}"
                )

            writer.writerow(parts[:len(header)])
            count += 1

    print(f"{source_name} -> {target_name}: {count:,} рядків")
    return count


def main() -> None:
    print(f"Джерело: {SOURCE_DIR}")
    print(f"CSV:     {TARGET_DIR}")

    for name in ("movies.dat", "ratings.dat", "users.dat"):
        if not (SOURCE_DIR / name).is_file():
            raise FileNotFoundError(f"Не знайдено {SOURCE_DIR / name}")

    convert_file("movies.dat", "movies.csv", ["movieId", "title", "genres"], 3)
    convert_file("ratings.dat", "ratings.csv", ["userId", "movieId", "rating", "timestamp"], 4)
    convert_file("users.dat", "users.csv", ["userId", "gender", "age", "occupation"], 5)
    print("Готово. Три CSV-файли доступні Neo4j у папці import/.")



main()
