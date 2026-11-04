import { Component, input } from '@angular/core';
import { STATUS_CLASS, STATUS_LABEL } from '../core/util';

@Component({
  selector: 'app-status',
  template: `<span class="chip" [class]="cls()">{{ label() }}</span>`,
})
export class StatusChip {
  readonly status = input<string | null | undefined>(null);
  cls(): string { return STATUS_CLASS[this.status() ?? ''] ?? ''; }
  label(): string { return STATUS_LABEL[this.status() ?? ''] ?? '—'; }
}
