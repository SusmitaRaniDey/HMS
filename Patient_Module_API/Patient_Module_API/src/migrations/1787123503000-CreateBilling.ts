import { MigrationInterface, QueryRunner } from 'typeorm';

export class CreateBilling1787123503000 implements MigrationInterface {
  name = 'CreateBilling1787123503000';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`
      CREATE TABLE billing (
        id int NOT NULL AUTO_INCREMENT,
        invoice_number varchar(20) NULL,
        patient_id int NOT NULL,
        appointment_id int NULL,
        diagnostic_booking_id int NULL,
        bill_type varchar(50) NOT NULL,
        subtotal decimal(10,2) NOT NULL,
        discount decimal(10,2) NOT NULL DEFAULT 0,
        tax decimal(10,2) NOT NULL DEFAULT 0,
        total_amount decimal(10,2) NOT NULL,
        payment_method varchar(100) NOT NULL,
        payment_status varchar(50) NOT NULL,
        transaction_id varchar(255) NULL,
        currency varchar(10) NOT NULL DEFAULT 'BDT',
        invoice_date timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        description text NULL,
        created_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
        updated_at timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY UQ_billing_invoice_number (invoice_number),
        UNIQUE KEY UQ_billing_appointment_id (appointment_id),
        UNIQUE KEY UQ_billing_diagnostic_booking_id (diagnostic_booking_id),
        INDEX IDX_billing_patient_id (patient_id),
        INDEX IDX_billing_transaction_id (transaction_id),
        INDEX IDX_billing_bill_type (bill_type),
        INDEX IDX_billing_payment_status (payment_status),
        INDEX IDX_billing_invoice_date (invoice_date),
        CONSTRAINT FK_billing_patient_id FOREIGN KEY (patient_id) REFERENCES patients(id) ON DELETE CASCADE,
        CONSTRAINT FK_billing_appointment_id FOREIGN KEY (appointment_id) REFERENCES appointment(id) ON DELETE SET NULL,
        CONSTRAINT FK_billing_diagnostic_booking_id FOREIGN KEY (diagnostic_booking_id) REFERENCES diagnostic_booking(id) ON DELETE SET NULL,
        PRIMARY KEY (id)
      ) ENGINE=InnoDB
    `);
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query('DROP TABLE billing');
  }
}
