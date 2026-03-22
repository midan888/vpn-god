import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api/client';
import type { AdminServerResponse, CreateServerRequest } from '../types';
import StatusBadge from '../components/StatusBadge';
import TrafficDisplay from '../components/TrafficDisplay';
import AddServerModal from '../components/AddServerModal';
import ConfirmModal from '../components/ConfirmModal';

export default function ServersPage() {
  const [servers, setServers] = useState<AdminServerResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showAdd, setShowAdd] = useState(false);
  const [deleteServer, setDeleteServer] = useState<AdminServerResponse | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchServers = async () => {
    try {
      const data = await api.listServers();
      setServers(data ?? []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load servers');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchServers();
  }, []);

  const handleAddServer = async (data: CreateServerRequest) => {
    const created = await api.createServer(data);
    setServers((prev) => [...prev, created]);
    setShowAdd(false);
  };

  const handleDeleteServer = async () => {
    if (!deleteServer) return;
    setDeleting(true);
    try {
      await api.deleteServer(deleteServer.id);
      setServers((prev) => prev.filter((s) => s.id !== deleteServer.id));
      setDeleteServer(null);
    } finally {
      setDeleting(false);
    }
  };

  const handleToggleActive = async (server: AdminServerResponse) => {
    try {
      await api.updateServer(server.id, { is_active: !server.is_active });
      setServers((prev) =>
        prev.map((s) => (s.id === server.id ? { ...s, is_active: !s.is_active } : s))
      );
    } catch {
      // Silently fail
    }
  };

  if (loading) return <div className="text-gray-500">Loading servers...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">
          Servers <span className="text-gray-400 font-normal text-lg">({servers.length})</span>
        </h1>
        <button
          onClick={() => setShowAdd(true)}
          className="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-lg hover:bg-blue-700 transition-colors"
        >
          Add Server
        </button>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <table className="w-full text-sm text-left">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 font-medium text-gray-500">Name</th>
              <th className="px-6 py-3 font-medium text-gray-500">Country</th>
              <th className="px-6 py-3 font-medium text-gray-500">Host</th>
              <th className="px-6 py-3 font-medium text-gray-500">Status</th>
              <th className="px-6 py-3 font-medium text-gray-500">Peers</th>
              <th className="px-6 py-3 font-medium text-gray-500">Traffic</th>
              <th className="px-6 py-3 font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {servers.map((server) => (
              <tr key={server.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <Link to={`/servers/${server.id}`} className="text-blue-600 hover:underline">
                    {server.name}
                  </Link>
                </td>
                <td className="px-6 py-4 text-gray-600">{server.country}</td>
                <td className="px-6 py-4 text-gray-600 font-mono text-xs">{server.host}</td>
                <td className="px-6 py-4">
                  <StatusBadge active={server.is_active} />
                </td>
                <td className="px-6 py-4 text-gray-600">{server.peer_count}</td>
                <td className="px-6 py-4">
                  <TrafficDisplay rx={server.rx_bytes} tx={server.tx_bytes} />
                </td>
                <td className="px-6 py-4">
                  <div className="flex gap-2">
                    <button
                      onClick={() => handleToggleActive(server)}
                      className="text-xs px-2.5 py-1 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
                    >
                      {server.is_active ? 'Deactivate' : 'Activate'}
                    </button>
                    <button
                      onClick={() => setDeleteServer(server)}
                      className="text-xs px-2.5 py-1 bg-red-50 text-red-600 rounded hover:bg-red-100 transition-colors"
                    >
                      Delete
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
        {servers.length === 0 && (
          <div className="text-center text-gray-400 py-12">No servers configured</div>
        )}
      </div>

      {showAdd && (
        <AddServerModal onSubmit={handleAddServer} onCancel={() => setShowAdd(false)} />
      )}

      {deleteServer && (
        <ConfirmModal
          title="Delete Server"
          message={`Are you sure you want to delete "${deleteServer.name}"? This will disconnect ${deleteServer.peer_count} active peer(s).`}
          onConfirm={handleDeleteServer}
          onCancel={() => setDeleteServer(null)}
          loading={deleting}
        />
      )}
    </div>
  );
}
