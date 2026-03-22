function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  const i = Math.floor(Math.log(bytes) / Math.log(1024));
  const value = bytes / Math.pow(1024, i);
  return `${value.toFixed(value < 10 && i > 0 ? 1 : 0)} ${units[i]}`;
}

interface Props {
  rx: number;
  tx: number;
}

export default function TrafficDisplay({ rx, tx }: Props) {
  if (rx === 0 && tx === 0) {
    return <span className="text-gray-400 text-sm">No traffic</span>;
  }
  return (
    <span className="text-sm">
      <span className="text-green-600">&darr;{formatBytes(rx)}</span>
      {' / '}
      <span className="text-blue-600">&uarr;{formatBytes(tx)}</span>
    </span>
  );
}

export { formatBytes };
