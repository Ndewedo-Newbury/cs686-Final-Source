from alembic import op
import sqlalchemy as sa

revision = '0002'
down_revision = '0001'

def upgrade():
    op.add_column('users', sa.Column('last_login', sa.DateTime(), nullable=True))

def downgrade():
    op.drop_column('users', 'last_login')
