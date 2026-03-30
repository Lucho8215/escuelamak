import { Injectable } from '@angular/core';

// Configuración de accesibilidad que se guarda en localStorage
export interface AccessibilityConfig {
  // Tipo de fuente: normal, dyslexic, monospace
  fontFamily: string;
  // Tamaño: 'small' | 'normal' | 'large' | 'xlarge'
  fontSize: string;
  // Alto contraste: true/false
  highContrast: boolean;
}

@Injectable({
  providedIn: 'root'
})
export class AccessibilityService {

  // Clave para guardar en localStorage
  private readonly STORAGE_KEY = 'escuelamak_accessibility';

  // Fuentes disponibles con su nombre CSS
  readonly fontOptions = [
    { id: 'inter',      name: 'Inter (predeterminada)', css: "'Inter', sans-serif" },
    { id: 'arial',      name: 'Arial (clara)',           css: "Arial, sans-serif" },
    { id: 'georgia',    name: 'Georgia (clásica)',       css: "Georgia, serif" },
    { id: 'comic',      name: 'Comic Sans (amigable)',   css: "'Comic Sans MS', cursive" },
    { id: 'mono',       name: 'Monospace (técnica)',     css: "'Courier New', monospace" },
    { id: 'opendys',    name: 'OpenDyslexic (dislexia)', css: "'OpenDyslexic', Arial, sans-serif" }
  ];

  // Tamaños disponibles
  readonly fontSizeOptions = [
    { id: 'small',  name: 'Pequeño',       value: '14px' },
    { id: 'normal', name: 'Normal',        value: '16px' },
    { id: 'large',  name: 'Grande',        value: '18px' },
    { id: 'xlarge', name: 'Muy grande',    value: '22px' }
  ];

  // Configuración actual
  private config: AccessibilityConfig = this.getDefaultConfig();

  // Estado del lector de voz
  private speaking = false;
  private synth = window.speechSynthesis;

  constructor() {
    // Al iniciar, cargamos y aplicamos la config guardada
    this.loadAndApply();
  }

  // Configuración por defecto
  private getDefaultConfig(): AccessibilityConfig {
    return {
      fontFamily: 'inter',
      fontSize: 'normal',
      highContrast: false
    };
  }

  // Carga config del localStorage y la aplica
  loadAndApply(): void {
    try {
      const saved = localStorage.getItem(this.STORAGE_KEY);
      if (saved) {
        this.config = { ...this.getDefaultConfig(), ...JSON.parse(saved) };
      }
    } catch {
      this.config = this.getDefaultConfig();
    }
    this.applyToDocument();
  }

  // Obtiene la config actual
  getConfig(): AccessibilityConfig {
    return { ...this.config };
  }

  // Guarda y aplica una nueva config
  saveConfig(config: AccessibilityConfig): void {
    this.config = { ...config };
    localStorage.setItem(this.STORAGE_KEY, JSON.stringify(this.config));
    this.applyToDocument();
  }

  // Aplica las variables CSS al documento completo
  private applyToDocument(): void {
    const root = document.documentElement;

    // Fuente
    const fontOption = this.fontOptions.find(f => f.id === this.config.fontFamily);
    const fontCss = fontOption?.css || "'Inter', sans-serif";
    root.style.setProperty('--app-font-family', fontCss);

    // Tamaño
    const sizeOption = this.fontSizeOptions.find(s => s.id === this.config.fontSize);
    const sizeCss = sizeOption?.value || '16px';
    root.style.setProperty('--app-font-size', sizeCss);

    // Alto contraste
    if (this.config.highContrast) {
      document.body.classList.add('alto-contraste');
    } else {
      document.body.classList.remove('alto-contraste');
    }
  }

  // ─── LECTOR DE VOZ ───────────────────────────────────────

  // Lee un texto en voz alta
  speak(text: string, lang: string = 'es-CO'): void {
    // Si ya está leyendo, lo detenemos primero
    this.stop();

    if (!text || !text.trim()) return;

    const utterance = new SpeechSynthesisUtterance(text.trim());
    utterance.lang = lang;
    utterance.rate = 0.85;  // Velocidad un poco más lenta para mayor claridad
    utterance.pitch = 1;
    utterance.volume = 1;

    utterance.onstart  = () => this.speaking = true;
    utterance.onend    = () => this.speaking = false;
    utterance.onerror  = () => this.speaking = false;

    this.synth.speak(utterance);
    this.speaking = true;
  }

  // Detiene la lectura
  stop(): void {
    if (this.synth.speaking) {
      this.synth.cancel();
    }
    this.speaking = false;
  }

  // ¿Está leyendo ahora mismo?
  isSpeaking(): boolean {
    return this.synth.speaking;
  }

  // Lee múltiples textos concatenados
  speakMultiple(texts: string[]): void {
    const combined = texts.filter(t => t && t.trim()).join('. ');
    this.speak(combined);
  }

  // Verifica si el navegador soporta TTS
  isSupported(): boolean {
    return 'speechSynthesis' in window;
  }
}