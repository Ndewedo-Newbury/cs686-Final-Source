import sys
from pathlib import Path

# Make `shared` importable when pytest runs from backend/auth-service/
sys.path.insert(0, str(Path(__file__).parent.parent.parent))
