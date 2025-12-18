import os
import uvicorn
import databases
from fastapi import FastAPI, HTTPException, status
from contextlib import asynccontextmanager

# --- 1. Конфигурация базы данных ---
# В реальном приложении это должно быть взято из .env файла или secrets.
# Формат URL для PostgreSQL с asyncpg (который используется библиотекой databases):
# postgresql+asyncpg://<user>:<password>@<host>:<port>/<db_name>
PG_PASS = os.environ.get("PG_PASS")
PG_URL = os.environ.get("PG_URL")
DB_NAME = os.environ.get("DB_NAME")
POSTGRES_PASS = os.environ.get("POSTGRES_PASS")
DATABASE_URL = f"postgresql+asyncpg://postgres:{POSTGRES_PASS}@{PG_URL}/{DB_NAME}" 
# Замените на реальные данные для подключения!

# Инициализация объекта базы данных
# Сама библиотека databases использует asyncpg для асинхронной работы с PostgreSQL
database = databases.Database(DATABASE_URL)


@asynccontextmanager
async def lifespan(app: FastAPI):
    """
    Менеджер контекста для управления жизненным циклом приложения.
    Подключение к DB, инициализация таблиц - на старте.
    Отключение от DB - при завершении работы.
    """
    
    print("--- 🚀 Подключение к базе данных и инициализация... ---")
    try:
        await database.connect()
        print("База данных успешно подключена.")

        # 1. Проверка и создание таблицы visits (CREATE TABLE IF NOT EXISTS)
        await database.execute(
            """
            CREATE TABLE IF NOT EXISTS visits (
                id INT PRIMARY KEY,
                count INT
            );
            """
        )
        
        # 2. Проверка и вставка начальной строки (INSERT INTO visits (1, 0))
        # Сначала проверяем, существует ли строка с id=1
        initial_count = await database.fetch_val("SELECT count FROM visits WHERE id = 1;")
        
        if initial_count is None:
            await database.execute("INSERT INTO visits (id, count) VALUES (1, 0);")
            print("Таблица 'visits' инициализирована начальной строкой (id=1, count=0).")
        else:
            print(f"Таблица 'visits' уже содержит данные. Текущий счетчик: {initial_count}")

    except Exception as e:
        # Критическая ошибка, если не удалось подключиться или выполнить DDL
        print(f"❌ ФАТАЛЬНАЯ ОШИБКА НА СТАРТЕ (DB): {e}")
        # В реальном приложении можно поднять HTTPException, чтобы остановить запуск.
        # Для демонстрации мы продолжим, но API будет возвращать ошибки 503.
        
    yield # Приложение запускается и обрабатывает запросы здесь

    # --- Shutdown Logic ---
    print("--- 🛑 Отключение от базы данных... ---")
    await database.disconnect()


# Инициализация FastAPI с использованием lifespan
app = FastAPI(
    title="PostgreSQL Visitor Counter API",
    version="1.0.0",
    lifespan=lifespan
)


@app.get("/", status_code=status.HTTP_200_OK)
async def increment_visitor_count():
    """
    Инкрементирует счетчик посещений в базе данных и возвращает обновленное значение.
    Выполняется в рамках одной атомарной транзакции.
    """
    try:
        # Выполнение транзакции: увеличение счетчика и возврат нового значения
        query = "UPDATE visits SET count = count + 1 WHERE id = 1 RETURNING count;"
        new_count = await database.fetch_val(query=query)

        if new_count is None:
            # Это может произойти, если в startup-логике не удалось вставить строку с id=1
            raise HTTPException(
                status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, 
                detail="Счетчик не инициализирован. Проверьте логи старта приложения."
            )

        return {"message": f"Hello! You are visitor number {new_count}"}

    except Exception as e:
        print(f"Ошибка при инкременте счетчика: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
            detail={"status": "error", "db_error": "Не удалось выполнить операцию с DB."}
        )


@app.get("/health", status_code=status.HTTP_200_OK)
async def health_check():
    """
    Проверяет соединение с базой данных простым запросом SELECT 1.
    """
    try:
        # Простая проверка соединения
        await database.fetch_one("SELECT 1")
        return {"status": "ok", "db": "connected"}
    except Exception as e:
        # Если запрос не прошел, база данных недоступна
        print(f"Health check провален: {e}")
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE, 
            detail={"status": "error", "db": "disconnected"}
        )


if __name__ == "__main__":
    # Запуск Uvicorn:
    # 1. Убедитесь, что у вас установлен Uvicorn, FastAPI, databases и asyncpg.
    #    pip install fastapi uvicorn[standard] databases[postgresql]
    # 2. Установите переменную окружения DATABASE_URL в терминале 
    #    (или используйте дефолтную строку, если PostgreSQL запущен локально)
    #    export DATABASE_URL="postgresql+asyncpg://..."
    # 3. Запустите:
    #    python main.py
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)