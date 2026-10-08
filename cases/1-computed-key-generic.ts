export const K = { A: 'a' } as const;
export type Fn = <X>({ [K.A]: X }: { [K.A]: X }) => void;
