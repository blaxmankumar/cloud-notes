import { useState, useEffect } from 'react';
import {
  Cloud,
  Database,
  Activity,
  FileText,
  Plus,
  Trash2,
  RefreshCw,
  CheckCircle2,
  XCircle,
  Loader2,
  Server,
  Github,
  Youtube,
  AlertCircle,
  Sparkles,
} from 'lucide-react';

const API_BASE = import.meta.env.VITE_API_URL || '';

function App() {
  const [notes, setNotes] = useState([]);
  const [dbStatus, setDbStatus] = useState(null);
  const [appHealth, setAppHealth] = useState(null);
  const [loading, setLoading] = useState(true);
  const [submitting, setSubmitting] = useState(false);
  const [error, setError] = useState(null);
  const [success, setSuccess] = useState(null);
  const [form, setForm] = useState({ title: '', content: '' });

  // Fetch everything on mount
  useEffect(() => {
    loadDashboard();
  }, []);

  // Auto-clear messages
  useEffect(() => {
    if (success || error) {
      const timer = setTimeout(() => {
        setSuccess(null);
        setError(null);
      }, 4000);
      return () => clearTimeout(timer);
    }
  }, [success, error]);

  async function loadDashboard() {
    setLoading(true);
    await Promise.all([fetchDbStatus(), fetchHealth(), fetchNotes()]);
    setLoading(false);
  }

  async function fetchDbStatus() {
    try {
      const res = await fetch(`${API_BASE}/api/db-status`);
      const data = await res.json();
      setDbStatus(data);
    } catch (err) {
      setDbStatus({ connected: false, error: 'Backend unreachable' });
    }
  }

  async function fetchHealth() {
    try {
      const res = await fetch(`${API_BASE}/health`);
      const data = await res.json();
      setAppHealth(data);
    } catch (err) {
      setAppHealth(null);
    }
  }

  async function fetchNotes() {
    try {
      const res = await fetch(`${API_BASE}/api/notes`);
      const data = await res.json();
      if (data.success) {
        setNotes(data.notes);
      }
    } catch (err) {
      setError('Failed to load notes');
    }
  }

  async function handleSubmit(e) {
    e.preventDefault();
    if (!form.title.trim()) {
      setError('Title is required');
      return;
    }

    setSubmitting(true);
    setError(null);

    try {
      const res = await fetch(`${API_BASE}/api/notes`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(form),
      });
      const data = await res.json();

      if (data.success) {
        setNotes([data.note, ...notes]);
        setForm({ title: '', content: '' });
        setSuccess('Note saved to RDS ✓');
      } else {
        setError(data.error || 'Failed to save note');
      }
    } catch (err) {
      setError('Network error. Is the backend running?');
    } finally {
      setSubmitting(false);
    }
  }

  async function handleDelete(id) {
    try {
      const res = await fetch(`${API_BASE}/api/notes/${id}`, {
        method: 'DELETE',
      });
      const data = await res.json();

      if (data.success) {
        setNotes(notes.filter((n) => n.id !== id));
        setSuccess('Note deleted from RDS');
      } else {
        setError(data.error || 'Failed to delete');
      }
    } catch (err) {
      setError('Network error');
    }
  }

  function formatDate(iso) {
    const d = new Date(iso);
    return d.toLocaleString('en-US', {
      month: 'short',
      day: 'numeric',
      hour: 'numeric',
      minute: '2-digit',
      hour12: true,
    });
  }

  const isConnected = dbStatus?.connected;

  return (
    <div className="min-h-screen bg-aws-dark bg-grid">
      {/* Header */}
      <header className="border-b border-aws-border bg-aws-dark/80 backdrop-blur-md sticky top-0 z-10">
        <div className="max-w-7xl mx-auto px-6 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-lg bg-gradient-to-br from-aws-orange to-orange-600 flex items-center justify-center">
              <Cloud className="w-6 h-6 text-white" />
            </div>
            <div>
              <h1 className="text-xl font-bold text-white tracking-tight">
                Cloud Notes
              </h1>
              <p className="text-xs text-aws-muted font-mono">
                Amazon RDS Dashboard
              </p>
            </div>
          </div>

          <div className="flex items-center gap-4">
            <a
              href="https://youtube.com/@awsandevops"
              target="_blank"
              rel="noopener noreferrer"
              className="hidden sm:flex items-center gap-2 text-sm text-aws-muted hover:text-white transition"
            >
              <Youtube className="w-4 h-4" />
              <span>@awsandevops</span>
            </a>
            <button
              onClick={loadDashboard}
              className="flex items-center gap-2 px-3 py-2 bg-aws-panel border border-aws-border rounded-lg text-sm text-white hover:border-aws-orange transition"
              disabled={loading}
            >
              <RefreshCw
                className={`w-4 h-4 ${loading ? 'animate-spin' : ''}`}
              />
              <span className="hidden sm:inline">Refresh</span>
            </button>
          </div>
        </div>
      </header>

      <main className="max-w-7xl mx-auto px-6 py-8">
        {/* Welcome banner */}
        <div className="mb-8 animate-fade-in">
          <div className="flex items-center gap-2 text-aws-orange text-sm font-medium mb-2">
            <Sparkles className="w-4 h-4" />
            <span>AWS Verified Access Protected · us-east-1</span>
          </div>
          <h2 className="text-3xl sm:text-4xl font-bold text-white tracking-tight">
            Cloud Notes · Zero Trust Protected Application
          </h2>
          <p className="text-aws-muted mt-2 max-w-2xl">
            Authenticated through AWS Verified Access at secure.lax-man.in.
            Access requires a verified corporate identity and approved group.
          </p>
        </div>

        {/* Status cards */}
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
          <StatusCard
            icon={Database}
            label="RDS Connection"
            value={
              loading
                ? 'Checking...'
                : isConnected
                ? 'Connected'
                : 'Disconnected'
            }
            status={isConnected ? 'success' : 'error'}
            loading={loading}
          />
          <StatusCard
            icon={FileText}
            label="Total Notes"
            value={loading ? '—' : notes.length}
            status="info"
            loading={loading}
          />
          <StatusCard
            icon={Server}
            label="DB Engine"
            value={
              loading
                ? '...'
                : isConnected
                ? `MySQL ${dbStatus?.version?.split('-')[0] || ''}`
                : 'N/A'
            }
            status={isConnected ? 'success' : 'muted'}
            loading={loading}
          />
          <StatusCard
            icon={Activity}
            label="App Health"
            value={
              loading
                ? '...'
                : appHealth
                ? `Up ${Math.floor(appHealth.uptime)}s`
                : 'Down'
            }
            status={appHealth ? 'success' : 'error'}
            loading={loading}
          />
        </div>

        {/* Endpoint info */}
        {dbStatus && (
          <div className="mb-8 card-glow border border-aws-border rounded-xl p-5 animate-slide-up">
            <div className="flex items-center justify-between flex-wrap gap-4">
              <div>
                <p className="text-xs text-aws-muted uppercase tracking-wider mb-1">
                  Connected Endpoint
                </p>
                <p className="font-mono text-sm text-white break-all">
                  {dbStatus.endpoint || 'Not configured'}
                </p>
              </div>
              <div className="flex items-center gap-4 text-xs text-aws-muted">
                <div>
                  <span className="text-aws-muted">Database: </span>
                  <span className="text-white font-mono">
                    {dbStatus.database}
                  </span>
                </div>
                <div>
                  <span className="text-aws-muted">Port: </span>
                  <span className="text-white font-mono">{dbStatus.port}</span>
                </div>
              </div>
            </div>
            {dbStatus.error && (
              <div className="mt-3 pt-3 border-t border-aws-border flex items-start gap-2 text-sm text-red-400">
                <AlertCircle className="w-4 h-4 mt-0.5 flex-shrink-0" />
                <span className="font-mono text-xs">{dbStatus.error}</span>
              </div>
            )}
          </div>
        )}

        {/* Toast messages */}
        {(success || error) && (
          <div
            className={`mb-6 px-4 py-3 rounded-lg border flex items-center gap-3 animate-slide-up ${
              success
                ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-300'
                : 'bg-red-500/10 border-red-500/30 text-red-300'
            }`}
          >
            {success ? (
              <CheckCircle2 className="w-5 h-5" />
            ) : (
              <XCircle className="w-5 h-5" />
            )}
            <span className="text-sm">{success || error}</span>
          </div>
        )}

        <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
          {/* Form */}
          <div className="lg:col-span-1">
            <div className="card-glow border border-aws-border rounded-xl p-6 sticky top-24">
              <div className="flex items-center gap-2 mb-5">
                <div className="w-8 h-8 rounded-lg bg-aws-orange/10 border border-aws-orange/30 flex items-center justify-center">
                  <Plus className="w-4 h-4 text-aws-orange" />
                </div>
                <h3 className="text-lg font-semibold text-white">New Note</h3>
              </div>

              <form onSubmit={handleSubmit} className="space-y-4">
                <div>
                  <label className="block text-xs text-aws-muted uppercase tracking-wider mb-2">
                    Title
                  </label>
                  <input
                    type="text"
                    value={form.title}
                    onChange={(e) =>
                      setForm({ ...form, title: e.target.value })
                    }
                    placeholder="My first RDS note"
                    className="w-full px-4 py-2.5 bg-aws-dark border border-aws-border rounded-lg text-white placeholder-aws-muted/60 focus:border-aws-orange"
                    maxLength={255}
                    disabled={!isConnected}
                  />
                </div>

                <div>
                  <label className="block text-xs text-aws-muted uppercase tracking-wider mb-2">
                    Content
                  </label>
                  <textarea
                    value={form.content}
                    onChange={(e) =>
                      setForm({ ...form, content: e.target.value })
                    }
                    placeholder="Write something..."
                    rows={5}
                    className="w-full px-4 py-2.5 bg-aws-dark border border-aws-border rounded-lg text-white placeholder-aws-muted/60 focus:border-aws-orange resize-none"
                    disabled={!isConnected}
                  />
                </div>

                <button
                  type="submit"
                  disabled={submitting || !isConnected || !form.title.trim()}
                  className="w-full py-2.5 bg-aws-orange text-aws-dark font-semibold rounded-lg hover:bg-aws-orange/90 disabled:opacity-40 disabled:cursor-not-allowed flex items-center justify-center gap-2"
                >
                  {submitting ? (
                    <>
                      <Loader2 className="w-4 h-4 animate-spin" />
                      Saving to RDS...
                    </>
                  ) : (
                    <>
                      <Database className="w-4 h-4" />
                      Save to RDS
                    </>
                  )}
                </button>

                {!isConnected && !loading && (
                  <p className="text-xs text-amber-400 text-center mt-2">
                    Connect to RDS to create notes
                  </p>
                )}
              </form>
            </div>
          </div>

          {/* Notes list */}
          <div className="lg:col-span-2">
            <div className="card-glow border border-aws-border rounded-xl">
              <div className="px-6 py-4 border-b border-aws-border flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <FileText className="w-5 h-5 text-aws-orange" />
                  <h3 className="text-lg font-semibold text-white">
                    Saved Notes
                  </h3>
                </div>
                <span className="text-xs text-aws-muted font-mono">
                  {notes.length} {notes.length === 1 ? 'row' : 'rows'} in RDS
                </span>
              </div>

              <div className="divide-y divide-aws-border">
                {loading ? (
                  <LoadingState />
                ) : notes.length === 0 ? (
                  <EmptyState connected={isConnected} />
                ) : (
                  notes.map((note) => (
                    <NoteRow
                      key={note.id}
                      note={note}
                      onDelete={handleDelete}
                      formatDate={formatDate}
                    />
                  ))
                )}
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <footer className="mt-12 pt-6 border-t border-aws-border flex flex-col sm:flex-row items-center justify-between gap-4 text-sm text-aws-muted">
          <p>
            Built for the <span className="text-white">AWS Zero to Hero</span>{' '}
            series · Madhukar Reddy
          </p>
          <div className="flex items-center gap-4">
            <a
              href="https://youtube.com/@awsandevops"
              target="_blank"
              rel="noopener noreferrer"
              className="flex items-center gap-1.5 hover:text-white transition"
            >
              <Youtube className="w-4 h-4" />
              YouTube
            </a>
            <a
              href="#"
              className="flex items-center gap-1.5 hover:text-white transition"
            >
              <Github className="w-4 h-4" />
              GitHub
            </a>
          </div>
        </footer>
      </main>
    </div>
  );
}

// ============================================
// Sub-components
// ============================================

function StatusCard({ icon: Icon, label, value, status, loading }) {
  const colors = {
    success: 'text-emerald-400 bg-emerald-500/10 border-emerald-500/20',
    error: 'text-red-400 bg-red-500/10 border-red-500/20',
    info: 'text-aws-orange bg-aws-orange/10 border-aws-orange/20',
    muted: 'text-aws-muted bg-aws-muted/10 border-aws-muted/20',
  };

  return (
    <div className="card-glow border border-aws-border rounded-xl p-5 hover:border-aws-orange/50 transition animate-slide-up">
      <div className="flex items-start justify-between mb-3">
        <div
          className={`w-9 h-9 rounded-lg border flex items-center justify-center ${colors[status]}`}
        >
          <Icon className="w-4 h-4" />
        </div>
        {status === 'success' && !loading && (
          <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse-slow" />
        )}
        {status === 'error' && !loading && (
          <span className="w-2 h-2 rounded-full bg-red-400" />
        )}
      </div>
      <p className="text-xs text-aws-muted uppercase tracking-wider mb-1">
        {label}
      </p>
      <p className="text-xl font-bold text-white font-mono">{value}</p>
    </div>
  );
}

function NoteRow({ note, onDelete, formatDate }) {
  return (
    <div className="px-6 py-4 hover:bg-aws-border/30 transition group animate-fade-in">
      <div className="flex items-start justify-between gap-4">
        <div className="flex-1 min-w-0">
          <div className="flex items-center gap-3 mb-1">
            <span className="text-xs font-mono text-aws-orange">
              #{note.id}
            </span>
            <h4 className="font-semibold text-white truncate">{note.title}</h4>
          </div>
          {note.content && (
            <p className="text-sm text-aws-muted leading-relaxed line-clamp-2">
              {note.content}
            </p>
          )}
          <p className="text-xs text-aws-muted/60 font-mono mt-2">
            {formatDate(note.created_at)}
          </p>
        </div>
        <button
          onClick={() => onDelete(note.id)}
          className="p-2 rounded-lg border border-transparent hover:border-red-500/30 hover:bg-red-500/10 text-aws-muted hover:text-red-400 transition opacity-0 group-hover:opacity-100"
          title="Delete note"
        >
          <Trash2 className="w-4 h-4" />
        </button>
      </div>
    </div>
  );
}

function LoadingState() {
  return (
    <div className="py-16 flex flex-col items-center justify-center text-aws-muted">
      <Loader2 className="w-8 h-8 animate-spin text-aws-orange mb-3" />
      <p className="text-sm">Loading notes from RDS...</p>
    </div>
  );
}

function EmptyState({ connected }) {
  return (
    <div className="py-16 flex flex-col items-center justify-center text-center px-6">
      <div className="w-16 h-16 rounded-2xl bg-aws-orange/10 border border-aws-orange/20 flex items-center justify-center mb-4">
        <Database className="w-8 h-8 text-aws-orange" />
      </div>
      <h4 className="text-lg font-semibold text-white mb-2">
        {connected ? 'No notes yet' : 'Database not connected'}
      </h4>
      <p className="text-sm text-aws-muted max-w-sm">
        {connected
          ? 'Create your first note using the form on the left. It will be stored in your Amazon RDS instance.'
          : 'Check your .env file and make sure your RDS security group allows access from this server.'}
      </p>
    </div>
  );
}

export default App;
