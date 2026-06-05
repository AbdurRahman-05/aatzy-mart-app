const db = require('../config/db');

// 1. GET ALL CATEGORIES
exports.getCategories = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM categories ORDER BY name ASC');
    return res.status(200).json({ success: true, categories: result.rows });
  } catch (error) {
    console.error('Get Categories Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 2. SEARCH & LIST PRODUCTS WITH FILTERS (Category, Location, Supplier Type, Search string)
exports.getProducts = async (req, res) => {
  try {
    const { categoryId, location, supplierType, query, page = 1, limit = 10 } = req.query;
    const offset = (page - 1) * limit;

    let sql = `
      SELECT p.*, s.company_name, s.location as supplier_location, s.business_type, c.name as category_name
      FROM products p
      JOIN suppliers s ON p.supplier_id = s.id
      LEFT JOIN categories c ON p.category_id = c.id
      WHERE p.status = 'Approved' AND p.deleted_at IS NULL
    `;
    const params = [];
    let paramIdx = 1;

    if (categoryId) {
      sql += ` AND p.category_id = $${paramIdx++}`;
      params.push(categoryId);
    }

    if (location) {
      sql += ` AND s.location ILIKE $${paramIdx++}`;
      params.push(`%${location}%`);
    }

    if (supplierType) {
      sql += ` AND s.business_type = $${paramIdx++}`;
      params.push(supplierType);
    }

    if (query) {
      sql += ` AND (p.name ILIKE $${paramIdx} OR p.description ILIKE $${paramIdx} OR s.company_name ILIKE $${paramIdx})`;
      params.push(`%${query}%`);
      paramIdx++;
    }

    sql += ` ORDER BY p.created_at DESC LIMIT $${paramIdx++} OFFSET $${paramIdx++}`;
    params.push(parseInt(limit), parseInt(offset));

    const result = await db.query(sql, params);

    // Fallback: If DB query returned nothing because it's running mock store
    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.products.filter(p => p.status === 'Approved');
      if (categoryId) rows = rows.filter(p => p.category_id == categoryId);
      if (query) rows = rows.filter(p => p.name.toLowerCase().includes(query.toLowerCase()));
    }

    return res.status(200).json({
      success: true,
      page: parseInt(page),
      limit: parseInt(limit),
      products: rows
    });
  } catch (error) {
    console.error('Get Products Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 3. GET SINGLE PRODUCT DETAIL
exports.getProductDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const sql = `
      SELECT p.*, s.company_name, s.description as supplier_description, s.location as supplier_location, s.business_type, s.website, s.logo_url
      FROM products p
      JOIN suppliers s ON p.supplier_id = s.id
      WHERE p.id = $1 AND p.deleted_at IS NULL
    `;
    const result = await db.query(sql, [id]);

    let product = result.rows[0];
    if (!product && db.dbMode() === 'memory') {
      const p = db.mockStore.products.find(item => item.id === id);
      if (p) {
        const s = db.mockStore.suppliers.find(sup => sup.id === p.supplier_id) || {};
        product = {
          ...p,
          company_name: s.company_name,
          supplier_description: s.description,
          supplier_location: s.location,
          business_type: s.business_type,
          website: s.website,
          logo_url: s.logo_url
        };
      }
    }

    if (!product) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    // Get Related Products
    const relatedRes = await db.query(
      'SELECT id, name, images FROM products WHERE category_id = $1 AND id != $2 AND status = \'Approved\' LIMIT 4',
      [product.category_id, product.id]
    );

    return res.status(200).json({
      success: true,
      product,
      relatedProducts: relatedRes.rows
    });
  } catch (error) {
    console.error('Get Product Detail Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 4. SEARCH & LIST SERVICES
exports.getServices = async (req, res) => {
  try {
    const { categoryId, query } = req.query;
    let sql = `
      SELECT s.*, sup.company_name, sup.location as supplier_location, sup.business_type
      FROM services s
      JOIN suppliers sup ON s.supplier_id = sup.id
      WHERE s.status = 'Approved' AND s.deleted_at IS NULL
    `;
    const params = [];
    let paramIdx = 1;

    if (categoryId) {
      sql += ` AND s.category_id = $${paramIdx++}`;
      params.push(categoryId);
    }
    if (query) {
      sql += ` AND (s.name ILIKE $${paramIdx} OR s.description ILIKE $${paramIdx} OR sup.company_name ILIKE $${paramIdx})`;
      params.push(`%${query}%`);
      paramIdx++;
    }

    const result = await db.query(sql, params);
    
    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.services.filter(s => s.status === 'Approved');
      if (categoryId) rows = rows.filter(s => s.category_id == categoryId);
      if (query) rows = rows.filter(s => s.name.toLowerCase().includes(query.toLowerCase()));
    }

    return res.status(200).json({ success: true, services: rows });
  } catch (error) {
    console.error('Get Services Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 5. SEND INQUIRY (LEAD GENERATION)
exports.sendInquiry = async (req, res) => {
  try {
    const { supplierId, productId, serviceId, title, description, quantity, unit, location, images } = req.body;
    
    // Authenticated user is buyer
    const userRes = await db.query('SELECT id FROM buyers WHERE user_id = $1', [req.user.id]);
    let buyer = userRes.rows[0];

    // Fallback if running offline
    if (!buyer && db.dbMode() === 'memory') {
      buyer = db.mockStore.buyers.find(b => b.user_id === req.user.id) || { id: 'mock-buyer-id' };
    }

    if (!buyer) {
      return res.status(403).json({ success: false, message: 'Only registered buyers can send inquiries' });
    }

    const inquiryId = require('crypto').randomUUID();

    const insertSql = `
      INSERT INTO inquiries (id, buyer_id, supplier_id, product_id, service_id, title, description, quantity, unit, location, images, status)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, 'New')
      RETURNING *
    `;

    const result = await db.query(insertSql, [
      inquiryId,
      buyer.id,
      supplierId,
      productId || null,
      serviceId || null,
      title,
      description,
      quantity,
      unit,
      location,
      images || []
    ]);

    const newInquiry = result.rows[0] || db.mockStore.inquiries.find(i => i.id === inquiryId);

    // Save status log
    await db.query(
      'INSERT INTO inquiry_status_logs (inquiry_id, status, notes, changed_by_user_id) VALUES ($1, $2, $3, $4)',
      [inquiryId, 'New', 'Inquiry submitted by buyer.', req.user.id]
    );

    // Trigger Push Notification to Supplier (Simulated)
    const supplierUserRes = await db.query('SELECT user_id FROM suppliers WHERE id = $1', [supplierId]);
    const supplierUserId = supplierUserRes.rows[0]?.user_id || db.mockStore.suppliers.find(s => s.id === supplierId)?.user_id;

    if (supplierUserId) {
      await db.query(
        'INSERT INTO notifications (user_id, title, body, payload) VALUES ($1, $2, $3, $4)',
        [
          supplierUserId,
          'New B2B Lead Received!',
          `Inquiry received: "${title}" (${quantity} ${unit})`,
          JSON.stringify({ inquiryId, type: 'new_lead' })
        ]
      );
      console.log(`[PUSH-NOTIFICATION] Sent to Supplier (${supplierUserId}): New Lead Received! - ${title}`);
    }

    return res.status(201).json({
      success: true,
      message: 'Inquiry submitted successfully',
      inquiry: newInquiry
    });
  } catch (error) {
    console.error('Send Inquiry Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 6. GET OWN INQUIRIES LIST (For Buyer Dashboard)
exports.getInquiries = async (req, res) => {
  try {
    const buyerRes = await db.query('SELECT id FROM buyers WHERE user_id = $1', [req.user.id]);
    let buyer = buyerRes.rows[0];

    if (!buyer && db.dbMode() === 'memory') {
      buyer = db.mockStore.buyers.find(b => b.user_id === req.user.id) || { id: 'mock-buyer-id' };
    }

    if (!buyer) {
      return res.status(403).json({ success: false, message: 'No buyer profile found' });
    }

    const sql = `
      SELECT i.*, s.company_name as supplier_name, s.logo_url as supplier_logo,
             p.name as product_name, serv.name as service_name
      FROM inquiries i
      JOIN suppliers s ON i.supplier_id = s.id
      LEFT JOIN products p ON i.product_id = p.id
      LEFT JOIN services serv ON i.service_id = serv.id
      WHERE i.buyer_id = $1
      ORDER BY i.created_at DESC
    `;
    const result = await db.query(sql, [buyer.id]);

    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.inquiries.filter(i => i.buyer_id === buyer.id).map(i => {
        const s = db.mockStore.suppliers.find(sup => sup.id === i.supplier_id) || {};
        const p = db.mockStore.products.find(prod => prod.id === i.product_id) || {};
        const serv = db.mockStore.services.find(ser => ser.id === i.service_id) || {};
        return {
          ...i,
          supplier_name: s.company_name,
          supplier_logo: s.logo_url,
          product_name: p.name || null,
          service_name: serv.name || null
        };
      });
    }

    return res.status(200).json({ success: true, inquiries: rows });
  } catch (error) {
    console.error('Get Inquiries Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 7. GET INQUIRY DETAIL WITH TIMELINE
exports.getInquiryDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const sql = `
      SELECT i.*, s.company_name as supplier_name, s.location as supplier_location,
             p.name as product_name, serv.name as service_name
      FROM inquiries i
      JOIN suppliers s ON i.supplier_id = s.id
      LEFT JOIN products p ON i.product_id = p.id
      LEFT JOIN services serv ON i.service_id = serv.id
      WHERE i.id = $1
    `;
    const inqRes = await db.query(sql, [id]);

    let inquiry = inqRes.rows[0];
    if (!inquiry && db.dbMode() === 'memory') {
      const i = db.mockStore.inquiries.find(item => item.id === id);
      if (i) {
        const s = db.mockStore.suppliers.find(sup => sup.id === i.supplier_id) || {};
        const p = db.mockStore.products.find(prod => prod.id === i.product_id) || {};
        const serv = db.mockStore.services.find(ser => ser.id === i.service_id) || {};
        inquiry = {
          ...i,
          supplier_name: s.company_name,
          supplier_location: s.location,
          product_name: p.name || null,
          service_name: serv.name || null
        };
      }
    }

    if (!inquiry) {
      return res.status(404).json({ success: false, message: 'Inquiry not found' });
    }

    // Fetch Status Timeline logs
    const timelineRes = await db.query(
      'SELECT l.*, u.name as changed_by_name FROM inquiry_status_logs l LEFT JOIN users u ON l.changed_by_user_id = u.id WHERE l.inquiry_id = $1 ORDER BY l.created_at ASC',
      [id]
    );

    return res.status(200).json({
      success: true,
      inquiry,
      timeline: timelineRes.rows
    });
  } catch (error) {
    console.error('Get Inquiry Detail Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 8. FAVORITES MANAGEMENT
exports.toggleFavorite = async (req, res) => {
  try {
    const { productId, serviceId } = req.body;
    const userId = req.user.id;

    if (!productId && !serviceId) {
      return res.status(400).json({ success: false, message: 'Either productId or serviceId is required' });
    }

    // Check if exists
    const checkSql = productId
      ? 'SELECT id FROM favorites WHERE user_id = $1 AND product_id = $2'
      : 'SELECT id FROM favorites WHERE user_id = $1 AND service_id = $2';
    
    const checkParams = productId ? [userId, productId] : [userId, serviceId];
    const checkRes = await db.query(checkSql, checkParams);

    if (checkRes.rows.length > 0) {
      // Remove favorite
      const deleteSql = productId
        ? 'DELETE FROM favorites WHERE user_id = $1 AND product_id = $2'
        : 'DELETE FROM favorites WHERE user_id = $1 AND service_id = $2';
      await db.query(deleteSql, checkParams);
      return res.status(200).json({ success: true, favorited: false, message: 'Removed from favorites' });
    } else {
      // Add favorite
      const insertSql = productId
        ? 'INSERT INTO favorites (user_id, product_id) VALUES ($1, $2)'
        : 'INSERT INTO favorites (user_id, service_id) VALUES ($1, $2)';
      await db.query(insertSql, checkParams);
      return res.status(200).json({ success: true, favorited: true, message: 'Added to favorites' });
    }
  } catch (error) {
    console.error('Toggle Favorite Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};

// 9. GET MATERIAL NEWS
exports.getNews = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM material_news ORDER BY published_at DESC');
    let rows = result.rows;
    if (rows.length === 0 && db.dbMode() === 'memory') {
      rows = db.mockStore.news || [];
    }
    return res.status(200).json({ success: true, news: rows });
  } catch (error) {
    console.error('Get News Error:', error);
    return res.status(500).json({ success: false, message: 'Internal Server Error' });
  }
};
