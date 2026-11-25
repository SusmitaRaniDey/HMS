import { Column, Entity, PrimaryColumn } from 'typeorm';

@Entity('medicine_data')
export class MedicineData {
  @PrimaryColumn({ type: 'int' })
  sl: number;

  @Column({ type: 'varchar', length: 100 })
  company: string;

  @Column({ type: 'varchar', length: 100 })
  trade_name: string;

  @Column({ type: 'varchar', length: 1000 })
  generic_name_with_strength: string;

  @Column({ type: 'varchar', length: 100 })
  dosage_form: string;

  @Column({ type: 'varchar', length: 50, name: 'dar_no' })
  dar_no: string;
}
