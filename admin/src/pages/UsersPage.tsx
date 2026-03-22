import { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api/client';
import type { AdminUserResponse } from '../types';
import StatusBadge from '../components/StatusBadge';
import ResetPasswordModal from '../components/ResetPasswordModal';
import ConfirmModal from '../components/ConfirmModal';

export default function UsersPage() {
  const [users, setUsers] = useState<AdminUserResponse[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [resetUser, setResetUser] = useState<AdminUserResponse | null>(null);
  const [deleteUser, setDeleteUser] = useState<AdminUserResponse | null>(null);
  const [deleting, setDeleting] = useState(false);

  const fetchUsers = async () => {
    try {
      const data = await api.listUsers();
      setUsers(data ?? []);
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Failed to load users');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchUsers();
  }, []);

  const handleResetPassword = async (newPassword: string) => {
    if (!resetUser) return;
    await api.resetPassword(resetUser.id, newPassword);
    setResetUser(null);
  };

  const handleDeleteUser = async () => {
    if (!deleteUser) return;
    setDeleting(true);
    try {
      await api.deleteUser(deleteUser.id);
      setUsers((prev) => prev.filter((u) => u.id !== deleteUser.id));
      setDeleteUser(null);
    } catch {
      // Error handled by modal
    } finally {
      setDeleting(false);
    }
  };

  if (loading) return <div className="text-gray-500">Loading users...</div>;
  if (error) return <div className="text-red-600">{error}</div>;

  return (
    <div>
      <div className="flex items-center justify-between mb-6">
        <h1 className="text-2xl font-bold text-gray-900">
          Users <span className="text-gray-400 font-normal text-lg">({users.length})</span>
        </h1>
      </div>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 overflow-hidden">
        <table className="w-full text-sm text-left">
          <thead className="bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-3 font-medium text-gray-500">Email</th>
              <th className="px-6 py-3 font-medium text-gray-500">Status</th>
              <th className="px-6 py-3 font-medium text-gray-500">Server</th>
              <th className="px-6 py-3 font-medium text-gray-500">IP</th>
              <th className="px-6 py-3 font-medium text-gray-500">Created</th>
              <th className="px-6 py-3 font-medium text-gray-500">Actions</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="px-6 py-4">
                  <Link to={`/users/${user.id}`} className="text-blue-600 hover:underline">
                    {user.email}
                  </Link>
                  {user.is_admin && (
                    <span className="ml-2 text-xs bg-purple-100 text-purple-700 px-1.5 py-0.5 rounded">
                      admin
                    </span>
                  )}
                </td>
                <td className="px-6 py-4">
                  <StatusBadge
                    active={!!user.peer}
                    label={user.peer ? `Connected` : 'Disconnected'}
                  />
                </td>
                <td className="px-6 py-4 text-gray-600">
                  {user.peer?.server_name ?? '-'}
                </td>
                <td className="px-6 py-4 text-gray-600 font-mono text-xs">
                  {user.peer?.assigned_ip ?? '-'}
                </td>
                <td className="px-6 py-4 text-gray-500">
                  {new Date(user.created_at).toLocaleDateString()}
                </td>
                <td className="px-6 py-4">
                  <div className="flex gap-2">
                    <button
                      onClick={() => setResetUser(user)}
                      className="text-xs px-2.5 py-1 bg-gray-100 text-gray-700 rounded hover:bg-gray-200 transition-colors"
                    >
                      Reset Password
                    </button>
                    <button
                      onClick={() => setDeleteUser(user)}
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
        {users.length === 0 && (
          <div className="text-center text-gray-400 py-12">No users found</div>
        )}
      </div>

      {resetUser && (
        <ResetPasswordModal
          userEmail={resetUser.email}
          onSubmit={handleResetPassword}
          onCancel={() => setResetUser(null)}
        />
      )}

      {deleteUser && (
        <ConfirmModal
          title="Delete User"
          message={`Are you sure you want to delete ${deleteUser.email}? This action cannot be undone.`}
          onConfirm={handleDeleteUser}
          onCancel={() => setDeleteUser(null)}
          loading={deleting}
        />
      )}
    </div>
  );
}
