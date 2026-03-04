from django.shortcuts import render
from .models import Slide

def index(request):
    slides = Slide.objects.all()
    return render(request, 'index.html', {'slides': slides})
