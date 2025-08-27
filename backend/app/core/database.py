from sqlalchemy import create_engine, text
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
import os
import time

SQLALCHEMY_DATABASE_URL = os.getenv(
    "DATABASE_URL", 
    "postgresql://postgres:postgres@postgres_app:5432/postgres"
)

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def wait_for_db():
    """Aguardar banco estar disponível"""
    max_retries = 30
    for i in range(max_retries):
        try:
            with engine.connect() as conn:
                conn.execute(text("SELECT 1"))
            print("✅ Database connection established")
            return True
        except Exception as e:
            print(f"⏳ Waiting for database... ({i+1}/{max_retries})")
            time.sleep(1)
    
    print("❌ Could not connect to database")
    return False

def create_tables():
    """Criar todas as tabelas"""
    try:
        print("🔧 Creating database tables...")
        
        # Aguardar banco estar disponível
        if not wait_for_db():
            return False
        
        # Importar modelos ANTES de criar tabelas
        from app.models.user import User, Base as UserBase
        
        # Criar tabelas usando o engine
        UserBase.metadata.create_all(bind=engine)
        
        print("✅ Tables created successfully")
        return True
        
    except Exception as e:
        print(f"❌ Error creating tables: {e}")
        return False

def table_exists(table_name: str) -> bool:
    """Verificar se tabela existe"""
    try:
        with engine.connect() as conn:
            result = conn.execute(text(f"""
                SELECT EXISTS (
                    SELECT FROM information_schema.tables 
                    WHERE table_name = '{table_name}'
                );
            """))
            return result.scalar()
    except:
        return False

def init_admin_user():
    """Criar usuário admin padrão"""
    try:
        # Verificar se tabela users existe
        if not table_exists('users'):
            print("❌ Users table does not exist, cannot create admin user")
            return False
        
        from app.models.user import User, UserRole
        
        db = SessionLocal()
        try:
            # Verificar se já existe admin
            admin = db.query(User).filter(User.username == "admin").first()
            if not admin:
                admin_user = User(
                    username="admin",
                    email="admin@pganalytics.com",
                    full_name="System Administrator",
                    role=UserRole.ADMIN,
                    hashed_password=User.get_password_hash("admin123"),
                    is_active=True,
                    is_verified=True
                )
                db.add(admin_user)
                db.commit()
                print("✅ Admin user created: admin/admin123")
            else:
                print("✅ Admin user already exists")
            return True
        finally:
            db.close()
            
    except Exception as e:
        print(f"❌ Error creating admin user: {e}")
        return False
