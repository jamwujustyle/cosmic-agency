from django.contrib import admin
from adminsortable2.admin import SortableAdminMixin
from django.utils.html import format_html
from easy_thumbnails.files import get_thumbnailer
from .models import Slide

@admin.register(Slide)
class SlideAdmin(SortableAdminMixin, admin.ModelAdmin):
    list_display = ('image_preview', 'title', 'order')
    list_display_links = ('image_preview', 'title')
    search_fields = ('title',)

    def image_preview(self, obj):
        if obj.image:
            # Generate thumbnail for admin preview
            try:
                thumbnail = get_thumbnailer(obj.image.file).get_thumbnail({
                    'size': (100, 75),
                    'crop': True,
                })
                return format_html('<img src="{}" style="border-radius:4px;" />', thumbnail.url)
            except Exception as e:
                return "Ошибка превью"
        return "Нет изображения"

    image_preview.short_description = 'Изображение'
