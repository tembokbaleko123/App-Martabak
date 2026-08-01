# Generated manually for flexible category feature
import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('menus', '0003_alter_menu_options_and_more'),
    ]

    operations = [
        # Step 1: Create Category table
        migrations.CreateModel(
            name='Category',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('name', models.CharField(max_length=50, unique=True)),
                ('sort_order', models.IntegerField(default=0, unique=True)),
                ('is_active', models.BooleanField(default=True)),
                ('created_at', models.DateTimeField(auto_now_add=True)),
                ('updated_at', models.DateTimeField(auto_now=True)),
            ],
            options={
                'verbose_name': 'Category',
                'verbose_name_plural': 'Categories',
                'db_table': 'categories',
                'ordering': ['sort_order', 'name'],
            },
        ),

        # Step 2: Insert default categories
        migrations.RunSQL(
            sql="INSERT INTO categories (name, sort_order, is_active, created_at, updated_at) VALUES ('Manis', 1, true, NOW(), NOW()), ('Telur', 2, true, NOW(), NOW()), ('Tipis', 3, true, NOW(), NOW())",
            reverse_sql="DELETE FROM categories WHERE name IN ('Manis', 'Telur', 'Tipis')",
        ),

        # Step 3: Add temporary column for FK (nullable bigint)
        migrations.AddField(
            model_name='menu',
            name='new_category_id',
            field=models.BigIntegerField(null=True, blank=True),
        ),

        # Step 4: Migrate data from string category to FK
        migrations.RunSQL(
            sql="""
                UPDATE menus
                SET new_category_id = CASE category
                    WHEN 'manis' THEN (SELECT id FROM categories WHERE name = 'Manis' LIMIT 1)
                    WHEN 'telur' THEN (SELECT id FROM categories WHERE name = 'Telur' LIMIT 1)
                    WHEN 'tipis' THEN (SELECT id FROM categories WHERE name = 'Tipis' LIMIT 1)
                    ELSE NULL
                END
            """,
            reverse_sql="UPDATE menus SET new_category_id = NULL",
        ),

        # Step 5: Remove old unique constraint
        migrations.RemoveConstraint(
            model_name='menu',
            name='unique_sort_order_per_category',
        ),

        # Step 6: Drop old category column
        migrations.RemoveField(
            model_name='menu',
            name='category',
        ),

        # Step 7: Rename new_category_id to category
        migrations.RenameField(
            model_name='menu',
            old_name='new_category_id',
            new_name='category',
        ),

        # Step 8: Alter category to be FK (now NOT NULL since data is migrated)
        migrations.AlterField(
            model_name='menu',
            name='category',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.SET_NULL,
                related_name='menus',
                to='menus.category'
            ),
        ),
    ]
