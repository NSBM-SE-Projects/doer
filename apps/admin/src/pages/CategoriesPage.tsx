import { useEffect, useState, FormEvent } from 'react';
import {
  getCategories,
  createCategory,
  updateCategory,
  deleteCategory,
} from '../services/api';
import {
  Plus,
  Pencil,
  Trash2,
  X,
  FolderOpen,
} from 'lucide-react';

export default function CategoriesPage() {
  const [categories, setCategories] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [formData, setFormData] = useState({ name: '', description: '', iconUrl: '' });
  const [formLoading, setFormLoading] = useState(false);

  const fetchCategories = () => {
    setLoading(true);
    getCategories()
      .then((res) => setCategories(Array.isArray(res) ? res : res.categories || []))
      .catch(console.error)
      .finally(() => setLoading(false));
  };

  useEffect(() => {
    fetchCategories();
  }, []);

  const openCreate = () => {
    setEditingId(null);
    setFormData({ name: '', description: '', iconUrl: '' });
    setShowForm(true);
  };

  const openEdit = (cat: any) => {
    setEditingId(cat.id);
    setFormData({
      name: cat.name,
      description: cat.description || '',
      iconUrl: cat.iconUrl || '',
    });
    setShowForm(true);
  };

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault();
    setFormLoading(true);
    try {
      if (editingId) {
        await updateCategory(editingId, formData);
      } else {
        await createCategory(formData);
      }
      setShowForm(false);
      fetchCategories();
    } catch (err) {
      console.error(err);
    } finally {
      setFormLoading(false);
    }
  };

  const handleDelete = async (id: string) => {
    if (!confirm('Are you sure you want to delete this category?')) return;
    try {
      await deleteCategory(id);
      fetchCategories();
    } catch (err) {
      console.error(err);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="w-8 h-8 border-3 border-primary-200 border-t-primary-500 rounded-full animate-spin" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex items-center justify-between">
        <p className="text-sm text-warm-500">
          {categories.length} service categories
        </p>
        <button
          onClick={openCreate}
          className="flex items-center gap-2 px-4 py-2 bg-primary-500 text-white rounded-lg text-sm font-medium hover:bg-primary-600 transition-colors"
        >
          <Plus size={16} />
          Add Category
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4">
        {categories.map((cat) => (
          <div
            key={cat.id}
            className="bg-white rounded-xl border border-warm-300 p-5 hover:shadow-md transition-shadow"
          >
            <div className="flex items-start justify-between">
              <div className="flex items-center gap-3">
                <div className="w-10 h-10 bg-primary-50 rounded-lg flex items-center justify-center">
                  {cat.iconUrl ? (
                    <img
                      src={cat.iconUrl}
                      alt=""
                      className="w-6 h-6"
                    />
                  ) : (
                    <FolderOpen size={18} className="text-primary-600" />
                  )}
                </div>
                <div>
                  <h4 className="font-medium text-warm-800">{cat.name}</h4>
                  {cat.description && (
                    <p className="text-xs text-warm-500 mt-0.5 line-clamp-2">
                      {cat.description}
                    </p>
                  )}
                </div>
              </div>
            </div>
            <div className="flex items-center gap-2 mt-4 pt-3 border-t border-warm-200">
              <button
                onClick={() => openEdit(cat)}
                className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 text-sm text-warm-600 hover:bg-warm-100 rounded-lg transition-colors"
              >
                <Pencil size={14} />
                Edit
              </button>
              <button
                onClick={() => handleDelete(cat.id)}
                className="flex-1 flex items-center justify-center gap-1 px-3 py-1.5 text-sm text-red-600 hover:bg-red-50 rounded-lg transition-colors"
              >
                <Trash2 size={14} />
                Delete
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Form Modal */}
      {showForm && (
        <div className="fixed inset-0 bg-black/50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl max-w-md w-full">
            <div className="p-6 border-b border-warm-300 flex items-center justify-between">
              <h3 className="font-semibold text-warm-800">
                {editingId ? 'Edit Category' : 'New Category'}
              </h3>
              <button
                onClick={() => setShowForm(false)}
                className="text-warm-400 hover:text-warm-700"
              >
                <X size={20} />
              </button>
            </div>
            <form onSubmit={handleSubmit} className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-warm-700 mb-1">
                  Name *
                </label>
                <input
                  type="text"
                  value={formData.name}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, name: e.target.value }))
                  }
                  required
                  className="w-full px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-warm-700 mb-1">
                  Description
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, description: e.target.value }))
                  }
                  rows={3}
                  className="w-full px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400 resize-none"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-warm-700 mb-1">
                  Icon URL
                </label>
                <input
                  type="url"
                  value={formData.iconUrl}
                  onChange={(e) =>
                    setFormData((f) => ({ ...f, iconUrl: e.target.value }))
                  }
                  className="w-full px-3 py-2 border border-warm-300 rounded-lg text-sm focus:outline-none focus:ring-2 focus:ring-primary-400"
                  placeholder="https://..."
                />
              </div>
              <div className="flex gap-3 pt-2">
                <button
                  type="button"
                  onClick={() => setShowForm(false)}
                  className="flex-1 px-4 py-2 border border-warm-300 text-warm-700 rounded-lg text-sm font-medium hover:bg-warm-50 transition-colors"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  disabled={formLoading}
                  className="flex-1 px-4 py-2 bg-primary-500 text-white rounded-lg text-sm font-medium hover:bg-primary-600 disabled:opacity-50 transition-colors"
                >
                  {formLoading ? 'Saving...' : editingId ? 'Update' : 'Create'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
