import { Injectable } from '@angular/core';
import { Observable, of } from 'rxjs';

export interface LearningModule {
  id: string;
  title: string;
  description: string;
  icon: string;
  color: string;
}

@Injectable({
  providedIn: 'root'
})
export class ModuleService {
  // Simulación de módulos - En producción, esto vendría de una API
  private modules: LearningModule[] = [
    {
      id: '1',
      title: '¡Números Mágicos!',
      description: 'Aprende a contar del 1 al 10',
      icon: 'fa-dice-d20',
      color: 'numbers-card'
    },
    {
      id: '2',
      title: '¡Formas Divertidas!',
      description: 'Descubre círculos y cuadrados',
      icon: 'fa-shapes',
      color: 'shapes-card'
    },
    {
      id: '3',
      title: '¡Sumas Mágicas!',
      description: 'Aprende a sumar jugando',
      icon: 'fa-plus-minus',
      color: 'games-card'
    },
    {
      id: '4',
      title: '¡Colores y Números!',
      description: 'Mezcla colores y números',
      icon: 'fa-palette',
      color: 'theme-card'
    }
  ];

  getModules(): Observable<LearningModule[]> {
    return of(this.modules);
  }
}