interface Props {
  active: boolean;
  label?: string;
}

export default function StatusBadge({ active, label }: Props) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-medium ${
        active
          ? 'bg-green-100 text-green-800'
          : 'bg-gray-100 text-gray-600'
      }`}
    >
      <span
        className={`w-1.5 h-1.5 rounded-full ${
          active ? 'bg-green-500' : 'bg-gray-400'
        }`}
      />
      {label ?? (active ? 'Active' : 'Inactive')}
    </span>
  );
}
