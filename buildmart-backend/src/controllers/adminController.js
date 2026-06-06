const prisma = require('../config/prisma');
const db = require('../config/db');

// 1. DASHBOARD ANALYTICS OVERVIEW
exports.getOverviewStats = async (req, res) => {
  try {
    const usersCount = await db.query('SELECT COUNT(*) FROM users WHERE deleted_at IS NULL');
    const suppliersCount = await db.query('SELECT COUNT(*) FROM suppliers WHERE deleted_at IS NULL');
    const productsCount = await db.query('SELECT COUNT(*) FROM products WHERE deleted_at IS NULL');
    const leadsCount = await db.query('SELECT COUNT(*) FROM inquiries');
    const categoriesCount = await db.query('SELECT COUNT(*) FROM categories');

    let stats = {
      users: parseInt(usersCount.rows[0]?.count || 0),
      suppliers: parseInt(suppliersCount.rows[0]?.count || 0),
      products: parseInt(productsCount.rows[0]?.count || 0),
      leads: parseInt(leadsCount.rows[0]?.count || 0),
      categories: parseInt(categoriesCount.rows[0]?.count || 0)
    };

    if (db.dbMode() === 'memory') {
      stats = {
        users: db.mockStore.users.length,
        suppliers: db.mockStore.suppliers.length,
        products: db.mockStore.products.length,
        leads: db.mockStore.inquiries.length,
        categories: db.mockStore.categories.length
      };
    }

    return res.status(200).json({ success: true, stats });
  } catch (error) {
    console.error('Admin Overview Stats Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 2. USER MANAGEMENT
exports.getUsers = async (req, res) => {
  try {
    const result = await db.query(
      'SELECT u.id, u.name, u.email, u.phone, u.is_active, u.created_at, r.name as role_name FROM users u JOIN roles r ON u.role_id = r.id WHERE u.deleted_at IS NULL'
    );
    
    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.users.map(u => {
        const r = db.mockStore.roles.find(item => item.id === u.role_id) || {};
        return { ...u, role_name: r.name };
      });
    }

    return res.status(200).json({ success: true, users: rows });
  } catch (error) {
    console.error('Admin Get Users Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.toggleUserStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { isActive } = req.body;

    await db.query('UPDATE users SET is_active = $1 WHERE id = $2', [isActive, id]);

    if (db.dbMode() === 'memory') {
      const u = db.mockStore.users.find(item => item.id === id);
      if (u) u.is_active = isActive;
    }

    return res.status(200).json({
      success: true,
      message: `User status changed to ${isActive ? 'Active' : 'Suspended'}`
    });
  } catch (error) {
    console.error('Toggle User Status Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.deleteUser = async (req, res) => {
  try {
    const { id } = req.params;

    if (db.dbMode() === 'postgres') {
      // Run cleanup and hard delete inside a transaction
      await db.query('BEGIN');
      try {
        await db.query('DELETE FROM activity_logs WHERE user_id = $1', [id]);
        await db.query('UPDATE inquiry_status_logs SET changed_by_user_id = NULL WHERE changed_by_user_id = $1', [id]);
        await db.query('UPDATE suppliers SET approved_by = NULL WHERE approved_by = $1', [id]);
        await db.query('DELETE FROM users WHERE id = $1', [id]);
        await db.query('COMMIT');
      } catch (txnError) {
        await db.query('ROLLBACK');
        throw txnError;
      }
    }

    if (db.dbMode() === 'memory') {
      // 1. Delete user from mockStore
      const userIdx = db.mockStore.users.findIndex(item => item.id === id);
      if (userIdx !== -1) {
        db.mockStore.users.splice(userIdx, 1);
      }
      // 2. Cascade delete from buyers or suppliers
      const buyerIdx = db.mockStore.buyers.findIndex(item => item.user_id === id);
      if (buyerIdx !== -1) {
        db.mockStore.buyers.splice(buyerIdx, 1);
      }
      const supplierIdx = db.mockStore.suppliers.findIndex(item => item.user_id === id);
      if (supplierIdx !== -1) {
        db.mockStore.suppliers.splice(supplierIdx, 1);
      }
      // 3. Delete notifications
      db.mockStore.notifications = db.mockStore.notifications.filter(n => n.user_id !== id);
      // 4. Delete favorites
      db.mockStore.favorites = db.mockStore.favorites.filter(f => f.user_id !== id);
      // 5. Clean up inquiry_status_logs changed by user
      db.mockStore.inquiry_status_logs.forEach(log => {
        if (log.changed_by_user_id === id) {
          log.changed_by_user_id = null;
        }
      });
      // 6. Clean up supplier approved_by
      db.mockStore.suppliers.forEach(sup => {
        if (sup.approved_by === id) {
          sup.approved_by = null;
          sup.approved_at = null;
        }
      });
    }

    return res.status(200).json({ success: true, message: 'User deleted successfully from database' });
  } catch (error) {
    console.error('Delete User Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 3. SUPPLIER VERIFICATION
exports.getSuppliers = async (req, res) => {
  try {
    const result = await db.query(
      'SELECT s.*, u.name as owner_name, u.email as owner_email, u.phone as owner_phone FROM suppliers s JOIN users u ON s.user_id = u.id WHERE s.deleted_at IS NULL'
    );
    
    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.suppliers.map(s => {
        const u = db.mockStore.users.find(usr => usr.id === s.user_id) || {};
        return {
          ...s,
          owner_name: u.name,
          owner_email: u.email,
          owner_phone: u.phone
        };
      });
    }

    return res.status(200).json({ success: true, suppliers: rows });
  } catch (error) {
    console.error('Admin Get Suppliers Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.verifySupplier = async (req, res) => {
  try {
    const { id } = req.params;
    const { isApproved } = req.body;

    // Update using Prisma
    const supplier = await prisma.suppliers.update({
      where: { id: id },
      data: {
        is_approved: isApproved,
        approved_by: req.user.id,
        approved_at: new Date()
      },
      select: {
        user_id: true,
        company_name: true
      }
    });

    if (db.dbMode() === 'memory') {
      const sup = db.mockStore.suppliers.find(item => item.id === id);
      if (sup) {
        sup.is_approved = isApproved;
        sup.approved_by = req.user.id;
        sup.approved_at = new Date();
      }
    }

    if (supplier && supplier.user_id) {
      // Notify supplier owner using Prisma
      await prisma.notifications.create({
        data: {
          user_id: supplier.user_id,
          title: isApproved ? 'Business Approved!' : 'Business Listing Rejected',
          body: isApproved
            ? `Congratulations! "${supplier.company_name}" profile has been verified by the administrator.`
            : `Your supplier registration for "${supplier.company_name}" has been rejected.`,
          payload: { type: 'supplier_approval', isApproved }
        }
      });
      console.log(`[PUSH-NOTIFICATION] Sent to Supplier Owner (${supplier.user_id}): Business verification status ${isApproved}`);
    }

    return res.status(200).json({
      success: true,
      message: `Supplier business profile ${isApproved ? 'Approved' : 'Rejected'} successfully`
    });
  } catch (error) {
    console.error('Verify Supplier Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 4. PRODUCT MODERATION
exports.getPendingProducts = async (req, res) => {
  try {
    const result = await db.query(
      `SELECT p.*, s.company_name FROM products p JOIN suppliers s ON p.supplier_id = s.id WHERE p.status = 'Pending' AND p.deleted_at IS NULL`
    );
    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.products.filter(p => p.status === 'Pending').map(p => {
        const s = db.mockStore.suppliers.find(sup => sup.id === p.supplier_id) || {};
        return { ...p, company_name: s.company_name };
      });
    }
    return res.status(200).json({ success: true, products: rows });
  } catch (error) {
    console.error('Admin Get Pending Products Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.moderateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, rejectedReason } = req.body; // Approved, Rejected

    const result = await db.query(
      'UPDATE products SET status = $1, rejected_reason = $2, updated_at = NOW() WHERE id = $3 RETURNING supplier_id, name',
      [status, rejectedReason || null, id]
    );

    let product = result.rows[0];
    if (db.dbMode() === 'memory') {
      const p = db.mockStore.products.find(item => item.id === id);
      if (p) {
        p.status = status;
        p.rejected_reason = rejectedReason;
        product = p;
      }
    }

    if (product) {
      const supplierUserRes = await db.query('SELECT user_id FROM suppliers WHERE id = $1', [product.supplier_id]);
      const userId = supplierUserRes.rows[0]?.user_id || db.mockStore.suppliers.find(s => s.id === product.supplier_id)?.user_id;

      if (userId) {
        await db.query(
          'INSERT INTO notifications (user_id, title, body, payload) VALUES ($1, $2, $3, $4)',
          [
            userId,
            status === 'Approved' ? 'Product Approved!' : 'Product Listing Rejected',
            status === 'Approved'
              ? `Your product "${product.name}" has been approved and is now live.`
              : `Your product "${product.name}" has been rejected. Reason: ${rejectedReason}`,
            JSON.stringify({ type: 'product_moderation', status })
          ]
        );
      }
    }

    return res.status(200).json({ success: true, message: `Product listing moderated to: ${status}` });
  } catch (error) {
    console.error('Moderate Product Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 5. CATEGORY CRUD
exports.createCategory = async (req, res) => {
  try {
    const { name, description, image_url, parent_id } = req.body;
    const slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '');

    const sql = `
      INSERT INTO categories (name, description, slug, image_url, parent_id)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING *
    `;
    const result = await db.query(sql, [name, description, slug, image_url, parent_id || null]);
    
    let newCategory = result.rows[0];
    if (db.dbMode() === 'memory') {
      newCategory = {
        id: db.mockStore.categories.length + 1,
        name,
        description,
        slug,
        image_url,
        parent_id,
        created_at: new Date()
      };
      db.mockStore.categories.push(newCategory);
    }

    return res.status(201).json({ success: true, category: newCategory });
  } catch (error) {
    console.error('Create Category Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.updateCategory = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, description, image_url, parent_id } = req.body;

    const slug = name ? name.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/(^-|-$)+/g, '') : null;

    const sql = `
      UPDATE categories
      SET name = COALESCE($1, name),
          description = COALESCE($2, description),
          slug = COALESCE($3, slug),
          image_url = COALESCE($4, image_url),
          parent_id = COALESCE($5, parent_id),
          updated_at = NOW()
      WHERE id = $6
      RETURNING *
    `;
    const result = await db.query(sql, [name, description, slug, image_url, parent_id, id]);

    let category = result.rows[0];
    if (db.dbMode() === 'memory') {
      const cat = db.mockStore.categories.find(c => c.id == id);
      if (cat) {
        if (name) { cat.name = name; cat.slug = slug; }
        if (description) cat.description = description;
        if (image_url) cat.image_url = image_url;
        if (parent_id !== undefined) cat.parent_id = parent_id;
        category = cat;
      }
    }

    return res.status(200).json({ success: true, category });
  } catch (error) {
    console.error('Update Category Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.deleteCategory = async (req, res) => {
  try {
    const { id } = req.params;

    if (db.dbMode() === 'postgres') {
      await db.query('BEGIN');
      try {
        await db.query('UPDATE products SET category_id = NULL WHERE category_id = $1', [id]);
        await db.query('UPDATE services SET category_id = NULL WHERE category_id = $1', [id]);
        await db.query('UPDATE categories SET parent_id = NULL WHERE parent_id = $1', [id]);
        await db.query('DELETE FROM categories WHERE id = $1', [id]);
        await db.query('COMMIT');
      } catch (txnError) {
        await db.query('ROLLBACK');
        throw txnError;
      }
    }

    if (db.dbMode() === 'memory') {
      const idx = db.mockStore.categories.findIndex(c => c.id == id);
      if (idx !== -1) {
        db.mockStore.categories.splice(idx, 1);
      }
      db.mockStore.products.forEach(p => {
        if (p.category_id == id) p.category_id = null;
      });
      db.mockStore.services.forEach(s => {
        if (s.category_id == id) s.category_id = null;
      });
      db.mockStore.categories.forEach(c => {
        if (c.parent_id == id) c.parent_id = null;
      });
    }

    return res.status(200).json({ success: true, message: 'Category deleted successfully' });
  } catch (error) {
    console.error('Delete Category Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
