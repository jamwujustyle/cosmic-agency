from django.db import models
from filer.fields.image import FilerImageField
from django.utils.translation import gettext_lazy as _

class Slide(models.Model):
    title = models.CharField(max_length=255, verbose_name=_('Название'))
    image = FilerImageField(
        null=True,
        blank=True,
        on_delete=models.SET_NULL,
        related_name='slides',
        verbose_name=_('Изображение')
    )
    order = models.PositiveIntegerField(
        default=0,
        blank=False,
        null=False,
        verbose_name=_('Порядок сортировки')
    )

    class Meta:
        ordering = ['order']
        verbose_name = _('Слайд')
        verbose_name_plural = _('Слайды')

    def __str__(self):
        return self.title
