revision = '0003'
down_revision = '0002'

def upgrade():
    op.drop_column('users', 'last_login')

def downgrade():
    op.add_column('users', sa.Column('last_login', sa.DateTime(), nullable=True))
