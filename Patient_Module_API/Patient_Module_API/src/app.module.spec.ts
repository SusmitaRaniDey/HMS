import { describe, expect, it } from '@jest/globals';
import { isSchemaSynchronizationAllowed } from './app.module';

describe('database startup safety', () => {
  it.each(['development', 'production', 'staging'])(
    'disables schema synchronization in %s even when requested',
    (nodeEnv) => {
      expect(isSchemaSynchronizationAllowed(true, nodeEnv)).toBe(false);
    },
  );

  it('allows synchronization only for an explicitly requested test database', () => {
    expect(isSchemaSynchronizationAllowed(true, 'test')).toBe(true);
    expect(isSchemaSynchronizationAllowed(false, 'test')).toBe(false);
  });
});
