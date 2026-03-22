import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import type { ServerTrafficResponse } from '../types';
import StatusBadge from '../components/StatusBadge';
import TrafficDisplay, { formatBytes } from '../components/TrafficDisplay';
import ConfirmModal from '../components/ConfirmModal';

export default function ServerDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [server, setServer] = useState<ServerTrafficResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showDelete, setShowDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    if (!id) return;
    api
      .getServer(id)
      .then(setServer)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [id]);

  const handleToggleActive = async () => {
    if (!id || !server) return;
    try {
      await api.updateServer(id, { is_active: !server.is_active });
      setServer((prev) => (prev ? { ...prev, is_active: !prev.is_active } : prev));
    } catch {
      // Silently fail
    }
  };

  const handleDelete = async () => {
    if (!id) return;
    setDeleting(true);
    try {
      await api.deleteServer(id);
      navigate('/servers', { replace: true });
    } finally {
      setDeleting(false);
    }
  };

  if (loading) return <div className="text-gray-500">Loading...</div>;
  if (error) return <div className="text-red-600">{error}</div>;
  if (!server) return <div className="text-gray-500">Server not found</div>;

  return (
    <div>
      <button
        onClick={() => navigate('/servers')}
        className="text-sm text-gray-500 hover:text-gray-700 mb-4"
      >
        &larr; Back to Servers
      </button>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">{server.name}</h1>
            <p className="text-sm text-gray-500 mt-1">
              {server.host}:{server.port} &middot; {server.country}
            </p>
          </div>
          <StatusBadge active={server.is_active} />
        </div>

        <div className="mt-6 grid grid-cols-2 gap-4">
          <div className="bg-gray-50 rounded-lg p-4">
            <div className="text-sm text-gray-500">Total Download</div>
            <div className="text-lg font-semibold text-green-600">
              {formatBytes(server.total_rx_bytes)}
            </div>
          </div>
          <div className="bg-gray-50 rounded-lg p-4">
            <div className="text-sm text-gray-500">Total Upload</div>
            <div className="text-lg font-semibold text-blue-600">
              {formatBytes(server.total_tx_bytes)}
            </div>
          </div>
        </div>

        <div className="mt-6 flex gap-3">
          <button
            onClick={handleToggleActive}
            className="px-4 py-2 text-sm font-medium bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
          >
            {server.is_active ? 'Deactivate' : 'Activate'}
          </button>
          <button
            onClick={() => setShowDelete(true)}
            className="px-4 py-2 text-sm font-medium bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
          >
            Delete Server
          </button>
        </div>
      </div>

      <div className="mt-6 bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <div className="px-6 py-4 border-b border-gray-200">
          <h2 className="text-lg font-semibold text-gray-900">
            Connected Peers ({server.peers?.length ?? 0})
          </h2>
        </div>
        <table className="w-full text-sm text-left">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 font-medium text-gray-500">Email</th>
              <th className="px-6 py-3 font-medium text-gray-500">IP</th>
              <th className="px-6 py-3 font-medium text-gray-500">Public Key</th>
              <th className="px-6 py-3 font-medium text-gray-500">Traffic</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {server.peers?.map((peer) => (
              <tr key={peer.public_key} className="hover:bg-gray-50">
                <td className="px-6 py-4 text-gray-900">{peer.email}</td>
                <td className="px-6 py-4 text-gray-600 font-mono text-xs">{peer.assigned_ip}</td>
                <td className="px-6 py-4 text-gray-500 font-mono text-xs truncate max-w-[200px]">
                  {peer.public_key}
                </td>
                <td className="px-6 py-4">
                  <TrafficDisplay rx={peer.rx_bytes} tx={peer.tx_bytes} />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {(!server.peers || server.peers.length === 0) && (
          <div className="text-center text-gray-400 py-12">No peers connected</div>
        )}
      </div>

      {showDelete && (
        <ConfirmModal
          title="Delete Server"
          message={`Are you sure you want to delete "${server.name}"? This will disconnect all active peers.`}
          onConfirm={handleDelete}
          onCancel={() => setShowDelete(false)}
          loading={deleting}
        />
      )}
    </div>
  );
}
