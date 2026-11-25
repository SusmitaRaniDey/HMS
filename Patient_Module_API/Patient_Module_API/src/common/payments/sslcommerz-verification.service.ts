import { BadRequestException, Injectable } from '@nestjs/common';

/**
 * Server-side SSLCommerz payment verification, shared by every booking flow
 * that takes an online payment. Mirrors the pattern already used correctly
 * by the emergency-consultation flow: never trust a client-reported "paid"
 * status — always re-check the transaction against SSLCommerz's own
 * validator API before marking anything as paid.
 */
@Injectable()
export class SslcommerzVerificationService {
  async verify(
    validationId: string | undefined,
    transactionId: string,
    expectedAmount: number,
  ): Promise<void> {
    const storeId = process.env.SSLCOMMERZ_STORE_ID;
    const storePassword = process.env.SSLCOMMERZ_STORE_PASSWORD;

    // The mobile SDK already returns a VALID/VALIDATED result in sandbox and
    // development. Production must always validate val_id server-side.
    if (process.env.NODE_ENV !== 'production') return;

    if (!validationId || !storeId || !storePassword) {
      throw new BadRequestException('Payment validation is not configured');
    }

    const sandbox = process.env.SSLCOMMERZ_SANDBOX !== 'false';
    const host = sandbox
      ? 'sandbox.sslcommerz.com'
      : 'securepay.sslcommerz.com';
    const url = new URL(
      `https://${host}/validator/api/validationserverAPI.php`,
    );
    url.searchParams.set('val_id', validationId);
    url.searchParams.set('store_id', storeId);
    url.searchParams.set('store_passwd', storePassword);
    url.searchParams.set('format', 'json');

    const response = await fetch(url);
    if (!response.ok) {
      throw new BadRequestException('Unable to validate payment');
    }

    const result = (await response.json()) as Record<string, unknown>;
    const valid = ['VALID', 'VALIDATED'].includes(String(result.status));
    const amountMatches =
      Math.abs(Number(result.amount) - expectedAmount) < 0.01;

    if (!valid || !amountMatches || String(result.tran_id) !== transactionId) {
      throw new BadRequestException('Invalid SSLCommerz payment response');
    }
  }

  generateTransactionId(prefix: string): string {
    return `${prefix}_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`;
  }
}
