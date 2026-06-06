const db = require('../config/db');

// Helper to get Supplier ID from Authenticated User
const getSupplierId = async (userId) => {
  const result = await db.query('SELECT id FROM suppliers WHERE user_id = $1', [userId]);
  if (result.rows.length > 0) return result.rows[0].id;
  
  if (db.dbMode() === 'memory') {
    const s = db.mockStore.suppliers.find(item => item.user_id === userId);
    if (s) return s.id;
  }
  return null;
};

// 1. SUPPLIER DASHBOARD STATS
exports.getDashboardStats = async (req, res) => {
  try {
    const supplierId = await getSupplierId(req.user.id);
    if (!supplierId) {
      return res.status(403).json({ success: false, message: 'Supplier profile not found' });
    }

    // Queries
    const prodCountRes = await db.query('SELECT COUNT(*) FROM products WHERE supplier_id = $1 AND deleted_at IS NULL', [supplierId]);
    const servCountRes = await db.query('SELECT COUNT(*) FROM services WHERE supplier_id = $1 AND deleted_at IS NULL', [supplierId]);
    const newLeadsRes = await db.query('SELECT COUNT(*) FROM inquiries WHERE supplier_id = $1 AND status = \'New\'', [supplierId]);
    const closedLeadsRes = await db.query('SELECT COUNT(*) FROM inquiries WHERE supplier_id = $1 AND status = \'Closed\'', [supplierId]);

    const totalProducts = parseInt(prodCountRes.rows[0]?.count || 0);
    const totalServices = parseInt(servCountRes.rows[0]?.count || 0);
    const newLeads = parseInt(newLeadsRes.rows[0]?.count || 0);
    const closedLeads = parseInt(closedLeadsRes.rows[0]?.count || 0);

    const stats = {
      totalProducts,
      totalServices,
      newLeads,
      closedLeads,
      leadTrends: [
        { month: 'Jan', count: 12 },
        { month: 'Feb', count: 19 },
        { month: 'Mar', count: 15 },
        { month: 'Apr', count: 28 },
        { month: 'May', count: 22 },
        { month: 'Jun', count: newLeads + closedLeads }
      ]
    };

    // Mock mode override helper
    if (db.dbMode() === 'memory') {
      const pCount = db.mockStore.products.filter(p => p.supplier_id === supplierId).length;
      const sCount = db.mockStore.services.filter(s => s.supplier_id === supplierId).length;
      const nCount = db.mockStore.inquiries.filter(i => i.supplier_id === supplierId && i.status === 'New').length;
      const cCount = db.mockStore.inquiries.filter(i => i.supplier_id === supplierId && i.status === 'Closed').length;
      
      stats.totalProducts = pCount;
      stats.totalServices = sCount;
      stats.newLeads = nCount;
      stats.closedLeads = cCount;
    }

    return res.status(200).json({ success: true, stats });
  } catch (error) {
    console.error('Supplier Dashboard Stats Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 2. UPDATE COMPANY PROFILE
exports.updateProfile = async (req, res) => {
  try {
    const { companyName, businessType, description, location, gstNumber, website, logoUrl, images } = req.body;
    const supplierId = await getSupplierId(req.user.id);

    if (!supplierId) {
      return res.status(403).json({ success: false, message: 'Supplier profile not found' });
    }

    const sql = `
      UPDATE suppliers
      SET company_name = COALESCE($1, company_name),
          business_type = COALESCE($2, business_type),
          description = COALESCE($3, description),
          location = COALESCE($4, location),
          gst_number = COALESCE($5, gst_number),
          website = COALESCE($6, website),
          logo_url = COALESCE($7, logo_url),
          images = COALESCE($8, images),
          updated_at = NOW()
      WHERE id = $9
      RETURNING *
    `;

    const result = await db.query(sql, [
      companyName, businessType, description, location, gstNumber, website, logoUrl, images, supplierId
    ]);

    const updatedProfile = result.rows[0] || db.mockStore.suppliers.find(s => s.id === supplierId);
    
    // In-memory simulation updates
    if (db.dbMode() === 'memory' && updatedProfile) {
      if (companyName) updatedProfile.company_name = companyName;
      if (businessType) updatedProfile.business_type = businessType;
      if (description) updatedProfile.description = description;
      if (location) updatedProfile.location = location;
      if (gstNumber) updatedProfile.gst_number = gstNumber;
      if (website) updatedProfile.website = website;
      if (logoUrl) updatedProfile.logo_url = logoUrl;
      if (images) updatedProfile.images = images;
    }

    return res.status(200).json({
      success: true,
      message: 'Business profile updated successfully',
      profile: updatedProfile
    });
  } catch (error) {
    console.error('Update Supplier Profile Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 3. PRODUCT MANAGEMENT
exports.addProduct = async (req, res) => {
  try {
    const { categoryId, name, description, specifications, images } = req.body;
    const supplierId = await getSupplierId(req.user.id);

    if (!supplierId) {
      return res.status(403).json({ success: false, message: 'Supplier profile not found' });
    }

    const id = require('crypto').randomUUID();
    const sql = `
      INSERT INTO products (id, supplier_id, category_id, name, description, specifications, images, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, 'Approved')
      RETURNING *
    `;
    const result = await db.query(sql, [
      id, supplierId, categoryId, name, description, JSON.stringify(specifications || {}), images || []
    ]);

    const newProduct = result.rows[0] || db.mockStore.products.find(p => p.id === id);

    return res.status(201).json({
      success: true,
      message: 'Product listing added and pending admin review',
      product: newProduct
    });
  } catch (error) {
    console.error('Add Product Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { categoryId, name, description, specifications, images } = req.body;
    const supplierId = await getSupplierId(req.user.id);

    const checkRes = await db.query('SELECT id FROM products WHERE id = $1 AND supplier_id = $2', [id, supplierId]);
    if (checkRes.rows.length === 0 && db.dbMode() !== 'memory') {
      return res.status(403).json({ success: false, message: 'Product not found or not owned by you' });
    }

    const sql = `
      UPDATE products
      SET category_id = COALESCE($1, category_id),
          name = COALESCE($2, name),
          description = COALESCE($3, description),
          specifications = COALESCE($4, specifications),
          images = COALESCE($5, images),
          status = 'Approved',
          updated_at = NOW()
      WHERE id = $6 AND supplier_id = $7
      RETURNING *
    `;
    const result = await db.query(sql, [
      categoryId, name, description, specifications ? JSON.stringify(specifications) : null, images, id, supplierId
    ]);

    const updatedProduct = result.rows[0] || db.mockStore.products.find(p => p.id === id);

    if (db.dbMode() === 'memory' && updatedProduct) {
      if (categoryId) updatedProduct.category_id = categoryId;
      if (name) updatedProduct.name = name;
      if (description) updatedProduct.description = description;
      if (specifications) updatedProduct.specifications = specifications;
      if (images) updatedProduct.images = images;
    }

    return res.status(200).json({
      success: true,
      message: 'Product updated successfully',
      product: updatedProduct
    });
  } catch (error) {
    console.error('Update Product Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const supplierId = await getSupplierId(req.user.id);

    // Soft delete
    const result = await db.query(
      'UPDATE products SET deleted_at = NOW() WHERE id = $1 AND supplier_id = $2 RETURNING *',
      [id, supplierId]
    );

    if (db.dbMode() === 'memory') {
      const idx = db.mockStore.products.findIndex(p => p.id === id && p.supplier_id === supplierId);
      if (idx !== -1) {
        db.mockStore.products.splice(idx, 1);
      }
    }

    return res.status(200).json({ success: true, message: 'Product deleted successfully' });
  } catch (error) {
    console.error('Delete Product Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 4. SERVICE MANAGEMENT
exports.addService = async (req, res) => {
  try {
    const { categoryId, name, description, images } = req.body;
    const supplierId = await getSupplierId(req.user.id);

    if (!supplierId) {
      return res.status(403).json({ success: false, message: 'Supplier profile not found' });
    }

    const id = require('crypto').randomUUID();
    const sql = `
      INSERT INTO services (id, supplier_id, category_id, name, description, images, status)
      VALUES ($1, $2, $3, $4, $5, $6, 'Pending')
      RETURNING *
    `;
    const result = await db.query(sql, [id, supplierId, categoryId, name, description, images || []]);
    const newService = result.rows[0] || db.mockStore.services.find(s => s.id === id);

    return res.status(201).json({
      success: true,
      message: 'Service listing added and pending admin review',
      service: newService
    });
  } catch (error) {
    console.error('Add Service Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.updateService = async (req, res) => {
  try {
    const { id } = req.params;
    const { categoryId, name, description, images } = req.body;
    const supplierId = await getSupplierId(req.user.id);

    const checkRes = await db.query('SELECT id FROM services WHERE id = $1 AND supplier_id = $2', [id, supplierId]);
    if (checkRes.rows.length === 0 && db.dbMode() !== 'memory') {
      return res.status(403).json({ success: false, message: 'Service not found or not owned by you' });
    }

    const sql = `
      UPDATE services
      SET category_id = COALESCE($1, category_id),
          name = COALESCE($2, name),
          description = COALESCE($3, description),
          images = COALESCE($4, images),
          status = 'Approved',
          updated_at = NOW()
      WHERE id = $5 AND supplier_id = $6
      RETURNING *
    `;
    const result = await db.query(sql, [
      categoryId, name, description, images, id, supplierId
    ]);

    const updatedService = result.rows[0] || db.mockStore.services.find(s => s.id === id);

    if (db.dbMode() === 'memory' && updatedService) {
      if (categoryId) updatedService.category_id = categoryId;
      if (name) updatedService.name = name;
      if (description) updatedService.description = description;
      if (images) updatedService.images = images;
    }

    return res.status(200).json({
      success: true,
      message: 'Service updated successfully',
      service: updatedService
    });
  } catch (error) {
    console.error('Update Service Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

exports.deleteService = async (req, res) => {
  try {
    const { id } = req.params;
    const supplierId = await getSupplierId(req.user.id);

    await db.query(
      'UPDATE services SET deleted_at = NOW() WHERE id = $1 AND supplier_id = $2',
      [id, supplierId]
    );

    if (db.dbMode() === 'memory') {
      const idx = db.mockStore.services.findIndex(s => s.id === id && s.supplier_id === supplierId);
      if (idx !== -1) {
        db.mockStore.services.splice(idx, 1);
      }
    }

    return res.status(200).json({ success: true, message: 'Service deleted successfully' });
  } catch (error) {
    console.error('Delete Service Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 5. VIEW LEADS (INQUIRIES)
exports.getLeads = async (req, res) => {
  try {
    const supplierId = await getSupplierId(req.user.id);
    if (!supplierId) {
      return res.status(403).json({ success: false, message: 'Supplier profile not found' });
    }

    const sql = `
      SELECT i.*, u.name as buyer_name, u.phone as buyer_phone, u.email as buyer_email,
             p.name as product_name, s.name as service_name
      FROM inquiries i
      JOIN buyers b ON i.buyer_id = b.id
      JOIN users u ON b.user_id = u.id
      LEFT JOIN products p ON i.product_id = p.id
      LEFT JOIN services s ON i.service_id = s.id
      WHERE i.supplier_id = $1
      ORDER BY i.created_at DESC
    `;
    const result = await db.query(sql, [supplierId]);

    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.inquiries.filter(i => i.supplier_id === supplierId).map(i => {
        const b = db.mockStore.buyers.find(buy => buy.id === i.buyer_id) || {};
        const u = db.mockStore.users.find(usr => usr.id === b.user_id) || { name: 'Demo Buyer', phone: '+919999999999' };
        const p = db.mockStore.products.find(prod => prod.id === i.product_id) || {};
        const s = db.mockStore.services.find(serv => serv.id === i.service_id) || {};
        return {
          ...i,
          buyer_name: u.name,
          buyer_phone: u.phone,
          buyer_email: u.email,
          product_name: p.name || null,
          service_name: s.name || null
        };
      });
    }

    return res.status(200).json({ success: true, leads: rows });
  } catch (error) {
    console.error('Get Supplier Leads Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 6. UPDATE LEAD STATUS (New, Viewed, Contacted, Closed) & ADD TIMELINE NOTES
exports.updateLeadStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status, notes, quotedPrice, deliveryStatus, gstPercent } = req.body;
    const supplierId = await getSupplierId(req.user.id);

    // Verify lead is for this supplier
    const checkSql = 'SELECT id, buyer_id, title FROM inquiries WHERE id = $1 AND supplier_id = $2';
    const checkRes = await db.query(checkSql, [id, supplierId]);
    
    let lead = checkRes.rows[0];
    if (!lead && db.dbMode() === 'memory') {
      lead = db.mockStore.inquiries.find(i => i.id === id && i.supplier_id === supplierId);
    }

    if (!lead) {
      return res.status(403).json({ success: false, message: 'Lead not found or not assigned to you' });
    }

    // Update status and quote details
    await db.query(
      'UPDATE inquiries SET status = $1, quoted_price = COALESCE($2, quoted_price), delivery_status = COALESCE($3, delivery_status), gst_percent = COALESCE($4, gst_percent), updated_at = NOW() WHERE id = $5',
      [status, quotedPrice, deliveryStatus, gstPercent, id]
    );
    
    if (db.dbMode() === 'memory') {
      const idx = db.mockStore.inquiries.findIndex(i => i.id === id);
      if (idx !== -1) {
        db.mockStore.inquiries[idx].status = status;
        if (quotedPrice !== undefined && quotedPrice !== null) db.mockStore.inquiries[idx].quoted_price = parseFloat(quotedPrice);
        if (deliveryStatus !== undefined && deliveryStatus !== null) db.mockStore.inquiries[idx].delivery_status = deliveryStatus;
        if (gstPercent !== undefined && gstPercent !== null) db.mockStore.inquiries[idx].gst_percent = parseFloat(gstPercent);
      }
    }

    // Insert timeline log
    await db.query(
      'INSERT INTO inquiry_status_logs (inquiry_id, status, notes, changed_by_user_id) VALUES ($1, $2, $3, $4)',
      [id, status, notes || `Lead status updated to: ${status}`, req.user.id]
    );

    // Send notification to Buyer that status has changed
    const buyerUserRes = await db.query('SELECT user_id FROM buyers WHERE id = $1', [lead.buyer_id]);
    const buyerUserId = buyerUserRes.rows[0]?.user_id || db.mockStore.buyers.find(b => b.id === lead.buyer_id)?.user_id;

    if (buyerUserId) {
      await db.query(
        'INSERT INTO notifications (user_id, title, body, payload) VALUES ($1, $2, $3, $4)',
        [
          buyerUserId,
          'Inquiry Status Update',
          `Your inquiry for "${lead.title}" status is now: ${status}.`,
          JSON.stringify({ inquiryId: id, type: 'status_update', status })
        ]
      );
      console.log(`[PUSH-NOTIFICATION] Sent to Buyer (${buyerUserId}): Inquiry status is now ${status}`);
    }

    return res.status(200).json({ success: true, message: 'Lead status updated successfully' });
  } catch (error) {
    console.error('Update Lead Status Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 7. GET MY PRODUCTS
exports.getProducts = async (req, res) => {
  try {
    const supplierId = await getSupplierId(req.user.id);
    if (!supplierId) {
      return res.status(403).json({ success: false, message: 'Supplier profile not found' });
    }

    const result = await db.query(
      'SELECT p.*, c.name as category_name FROM products p LEFT JOIN categories c ON p.category_id = c.id WHERE p.supplier_id = $1 AND p.deleted_at IS NULL ORDER BY p.created_at DESC',
      [supplierId]
    );

    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.products.filter(p => p.supplier_id === supplierId);
    }

    return res.status(200).json({ success: true, products: rows });
  } catch (error) {
    console.error('Get Supplier Products Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 8. GET MY SERVICES
exports.getServices = async (req, res) => {
  try {
    const supplierId = await getSupplierId(req.user.id);
    if (!supplierId) {
      return res.status(403).json({ success: false, message: 'Supplier profile not found' });
    }

    const result = await db.query(
      'SELECT s.*, c.name as category_name FROM services s LEFT JOIN categories c ON s.category_id = c.id WHERE s.supplier_id = $1 AND s.deleted_at IS NULL ORDER BY s.created_at DESC',
      [supplierId]
    );

    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.services.filter(s => s.supplier_id === supplierId);
    }

    return res.status(200).json({ success: true, services: rows });
  } catch (error) {
    console.error('Get Supplier Services Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
