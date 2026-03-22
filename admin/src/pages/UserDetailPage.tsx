import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import type { AdminUserResponse } from '../types';
import StatusBadge from '../components/StatusBadge';
import ResetPasswordModal from '../components/ResetPasswordModal';
import ConfirmModal from '../components/ConfirmModal';

export default function UserDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [user, setUser] = useState<AdminUserResponse | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [showReset, setShowReset] = useState(false);
  const [showDelete, setShowDelete] = useState(false);
  const [deleting, setDeleting] = useState(false);

  useEffect(() => {
    if (!id) return;
    api
      .getUser(id)
      .then(setUser)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [id]);

  const handleResetPassword = async (newPassword: string) => {
    if (!id) return;
    await api.resetPassword(id, newPassword);
    setShowReset(false);
  };

  const handleDelete = async () => {
    if (!id) return;
    setDeleting(true);
    try {
      await api.deleteUser(id);
      navigate('/users', { replace: true });
    } finally {
      setDeleting(false);
    }
  };

  if (loading) return <div className="text-gray-500">Loading...</div>;
  if (error) return <div className="text-red-600">{error}</div>;
  if (!user) return <div className="text-gray-500">User not found</div>;

  return (
    <div className="max-w-2xl">
      <button
        onClick={() => navigate('/users')}
        className="text-sm text-gray-500 hover:text-gray-700 mb-4"
      >
        &larr; Back to Users
      </button>

      <div className="bg-white rounded-xl shadow-sm border border-gray-200 p-6">
        <div className="flex items-center justify-between">
          <div>
            <h1 className="text-xl font-bold text-gray-900">{user.email}</h1>
            <p className="text-sm text-gray-500 mt-1">
              Created {new Date(user.created_at).toLocaleDateString()}
            </p>
          </div>
          <div className="flex items-center gap-2">
            {user.is_admin && (
              <span className="text-xs bg-purple-100 text-purple-700 px-2 py-1 rounded-full">
                Admin
              </span>
            )}
            <StatusBadge active={!!user.peer} label={user.peer ? 'Connected' : 'Disconnected'} />
          </div>
        </div>

        {user.peer && (
          <div className="mt-6 bg-gray-50 rounded-lg p-4">
            <h3 className="text-sm font-medium text-gray-700 mb-2">Active Connection</h3>
            <div className="grid grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-gray-500">Server:</span>{' '}
                <span className="font-medium">{user.peer.server_name}</span>
              </div>
              <div>
                <span className="text-gray-500">IP:</span>{' '}
                <span className="font-mono">{user.peer.assigned_ip}</span>
              </div>
              <div>
                <span className="text-gray-500">Connected since:</span>{' '}
                <span>{new Date(user.peer.connected_at).toLocaleString()}</span>
              </div>
            </div>
          </div>
        )}

        <div className="mt-6 flex gap-3">
          <button
            onClick={() => setShowReset(true)}
            className="px-4 py-2 text-sm font-medium bg-gray-100 text-gray-700 rounded-lg hover:bg-gray-200 transition-colors"
          >
            Reset Password
          </button>
          <button
            onClick={() => setShowDelete(true)}
            className="px-4 py-2 text-sm font-medium bg-red-50 text-red-600 rounded-lg hover:bg-red-100 transition-colors"
          >
            Delete User
          </button>
        </div>
      </div>

      {showReset && (
        <ResetPasswordModal
          userEmail={user.email}
          onSubmit={handleResetPassword}
          onCancel={() => setShowReset(false)}
        />
      )}

      {showDelete && (
        <ConfirmModal
          title="Delete User"
          message={`Are you sure you want to delete ${user.email}? This action cannot be undone.`}
          onConfirm={handleDelete}
          onCancel={() => setShowDelete(false)}
          loading={deleting}
        />
      )}
    </div>
  );
}
