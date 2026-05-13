
from alembic import op
import sqlalchemy as sa

revision = '0003'
down_revision = '0002'
branch_labels = None
depends_on = None


def upgrade():
    op.drop_column('users', 'last_login')


def downgrade():
    op.add_column('users', sa.Column('last_login', sa.DateTime(), nullable=True))
