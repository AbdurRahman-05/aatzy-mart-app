const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');
require('dotenv').config();

let dbMode = 'postgres';
let pool = null;

// Mock database in-memory store for fallback
const mockStore = {
  roles: [
    { id: 1, name: 'admin' },
    { id: 2, name: 'buyer' },
    { id: 3, name: 'supplier' }
  ],
  users: [
    {
      id: 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1',
      name: 'BuildMart Admin',
      email: 'admin@buildmart.com',
      phone: '+919999999999',
      password_hash: '$2a$10$3z8fW/fH6.U2FqJ1b10/beNf6Yv9r58xWnE5jKeqtA/1qU3VwXb7S', // 'password'
      role_id: 1,
      is_active: true,
      created_at: new Date()
    },
    {
      id: 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2',
      name: 'Rajesh Kumar',
      email: 'rajesh@ultratech.com',
      phone: '+919876543210',
      password_hash: '$2a$10$3z8fW/fH6.U2FqJ1b10/beNf6Yv9r58xWnE5jKeqtA/1qU3VwXb7S', // 'password'
      role_id: 3,
      is_active: true,
      created_at: new Date()
    },
    {
      id: 'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3',
      name: 'Amit Sharma',
      email: 'amit@condev.com',
      phone: '+919123456789',
      password_hash: '$2a$10$3z8fW/fH6.U2FqJ1b10/beNf6Yv9r58xWnE5jKeqtA/1qU3VwXb7S', // 'password'
      role_id: 2,
      is_active: true,
      created_at: new Date()
    }
  ],
  suppliers: [
    {
      id: 'd4d4d4d4-d4d4-d4d4-d4d4-d4d4d4d4d4d4',
      user_id: 'b2b2b2b2-b2b2-b2b2-b2b2-b2b2b2b2b2b2',
      company_name: 'UltraTech Build Solutions',
      business_type: 'Manufacturer',
      description: 'Leading manufacturer of structural cement, concrete aggregates, and premium building plaster solutions in India.',
      location: 'Mumbai, Maharashtra',
      gst_number: '27AAAAA1111A1Z1',
      website: 'https://www.ultratechcement.com',
      logo_url: 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?auto=format&fit=crop&q=80&w=200',
      images: ['https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=600'],
      is_approved: true,
      approved_by: 'a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1',
      approved_at: new Date(),
      created_at: new Date()
    }
  ],
  buyers: [
    {
      id: 'e5e5e5e5-e5e5-e5e5-e5e5-e5e5e5e5e5e5',
      user_id: 'c3c3c3c3-c3c3-c3c3-c3c3-c3c3c3c3c3c3',
      location: 'Delhi NCR',
      preferences: { preferred_categories: [1, 2, 8] },
      created_at: new Date()
    }
  ],
  categories: [
    { id: 1, name: 'Construction Materials', description: 'Cement, bricks, sand, concrete, and structural steel.', slug: 'construction-materials', parent_id: null, image_url: 'https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=400' },
    { id: 2, name: 'Electrical', description: 'Wires, cables, switches, switchgears, and industrial panels.', slug: 'electrical', parent_id: null, image_url: 'https://images.unsplash.com/photo-1581092160607-ee22621dd758?auto=format&fit=crop&q=80&w=400' },
    { id: 3, name: 'Plumbing', description: 'Pipes, fittings, valves, water tanks, and sanitary ware.', slug: 'plumbing', parent_id: null, image_url: 'https://images.unsplash.com/photo-1584622650111-993a426fbf0a?auto=format&fit=crop&q=80&w=400' },
    { id: 4, name: 'Interior Design', description: 'Decorative items, wallpapers, wall paneling, and acoustic panels.', slug: 'interior-design', parent_id: null, image_url: 'https://images.unsplash.com/photo-1616486338812-3dadae4b4ace?auto=format&fit=crop&q=80&w=400' },
    { id: 5, name: 'Machinery', description: 'Heavy industrial machines, concrete mixers, generators, and excavators.', slug: 'machinery', parent_id: null, image_url: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?auto=format&fit=crop&q=80&w=400' },
    { id: 6, name: 'Furniture', description: 'Office furniture, industrial racks, school benches, and modular workstations.', slug: 'furniture', parent_id: null, image_url: 'https://images.unsplash.com/photo-1524758631624-e2822e304c36?auto=format&fit=crop&q=80&w=400' },
    { id: 7, name: 'Paints', description: 'Wall paints, industrial coatings, primers, distempers, and painting tools.', slug: 'paints', parent_id: null, image_url: 'https://images.unsplash.com/photo-1562259949-e8e7689d7828?auto=format&fit=crop&q=80&w=400' },
    { id: 8, name: 'Hardware', description: 'Nails, screws, fasteners, locks, hinges, and power hand tools.', slug: 'hardware', parent_id: null, image_url: 'https://images.unsplash.com/photo-1534224039826-c7a0eda0e6b3?auto=format&fit=crop&q=80&w=400' },
    { id: 9, name: 'Solar & Energy', description: 'Solar panels, solar inverters, batteries, and wind turbine components.', slug: 'solar-energy', parent_id: null, image_url: 'https://images.unsplash.com/photo-1509391366360-2e959784a276?auto=format&fit=crop&q=80&w=400' },
    { id: 10, name: 'Architecture & Engineering', description: 'CAD drawings, blueprints, project consultancy, and structural modeling.', slug: 'architecture-engineering', parent_id: null, image_url: 'https://images.unsplash.com/photo-1503387762-592dec58ef4e?auto=format&fit=crop&q=80&w=400' }
  ],
  products: [],
  services: [],
  inquiries: [],
  inquiry_status_logs: [],
  favorites: [],
  notifications: [],
  news: [
    {
      id: 'news-1',
      title: 'Steel prices surge 5% in Indian retail markets',
      content: 'Retail prices for TMT steel rebars have surged across major metro hubs due to increased raw iron ore costs and seasonal infrastructure spikes.',
      category: 'Steel',
      published_at: '2026-06-05'
    },
    {
      id: 'news-2',
      title: 'Monsoon season prompts cement price reductions',
      content: 'In anticipation of the construction slowdown during heavy rains, top manufacturers like UltraTech and ACC have revised rates downward.',
      category: 'Cement',
      published_at: '2026-06-04'
    },
    {
      id: 'news-3',
      title: 'Green building guidelines: Mandatory fly-ash usage',
      content: 'The Ministry of Housing has released guidelines making fly-ash brick blends mandatory for new government-sponsored housing blocks.',
      category: 'Policy',
      published_at: '2026-06-01'
    }
  ],
  activity_logs: []
};

// Check DB Connection details
const connectionString = process.env.DATABASE_URL || '';

const initDatabaseSchema = async () => {
  try {
    const tableCheck = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = 'roles'
      );
    `);
    
    if (!tableCheck.rows[0].exists) {
      console.log('Database tables not found. Initializing database schema on Neon...');
      
      const migrationPath = path.join(__dirname, '../../db/migration.sql');
      const seedPath = path.join(__dirname, '../../db/seed.sql');
      
      if (fs.existsSync(migrationPath)) {
        const migrationSql = fs.readFileSync(migrationPath, 'utf8');
        await pool.query(migrationSql);
        console.log('Migration DDL applied successfully.');
      }
      
      if (fs.existsSync(seedPath)) {
        const seedSql = fs.readFileSync(seedPath, 'utf8');
        await pool.query(seedSql);
        console.log('Seed data inserted successfully.');
      }
    } else {
      console.log('Database schema already initialized. Checking if seed data is needed...');
      const roleCountCheck = await pool.query('SELECT COUNT(*) FROM roles');
      if (parseInt(roleCountCheck.rows[0].count) === 0) {
        console.log('Roles table is empty. Seeding required metadata roles and categories...');
        const seedPath = path.join(__dirname, '../../db/seed.sql');
        if (fs.existsSync(seedPath)) {
          const seedSql = fs.readFileSync(seedPath, 'utf8');
          await pool.query(seedSql);
          console.log('Seed data inserted successfully.');
        }
      } else {
        console.log('Database already has seeded data.');
      }
    }
    // Ensure suppliers table has materials_providing column
    await pool.query(`
      ALTER TABLE suppliers 
      ADD COLUMN IF NOT EXISTS materials_providing VARCHAR(512);
    `);
    
    // Ensure admin user exists in DB to prevent foreign key issues on verification
    await pool.query(`
      INSERT INTO users (id, name, email, phone, password_hash, role_id, is_active) 
      VALUES ('a1a1a1a1-a1a1-a1a1-a1a1-a1a1a1a1a1a1', 'BuildMart Admin', 'admin@buildmart.com', '+919999999999', '$2a$10$3z8fW/fH6.U2FqJ1b10/beNf6Yv9r58xWnE5jKeqtA/1qU3VwXb7S', 1, TRUE)
      ON CONFLICT (id) DO NOTHING;
    `);
  } catch (err) {
    console.error('Failed to initialize database schema:', err.message);
  }
};

if (connectionString || process.env.DB_HOST) {
  try {
    const isSSLNeeded = connectionString.includes('neon.tech') || connectionString.includes('sslmode=require');
    pool = new Pool({
      connectionString: connectionString || `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME}`,
      connectionTimeoutMillis: 5000,
      ssl: isSSLNeeded ? { rejectUnauthorized: false } : undefined
    });
    console.log('Successfully configured connection to PostgreSQL/Neon database.');
    dbMode = 'postgres';
    
    // Auto-run migrations if tables don't exist
    initDatabaseSchema();
  } catch (err) {
    console.warn('PostgreSQL configuration failed. Falling back to IN-MEMORY DATABASE. Error:', err.message);
    dbMode = 'memory';
  }
} else {
  console.warn('No DATABASE_URL or DB_HOST env variables found. Running backend in IN-MEMORY DATABASE mode.');
  dbMode = 'memory';
}

const query = async (text, params) => {
  if (dbMode === 'postgres' && pool) {
    return await pool.query(text, params);
  } else {
    return runMockQuery(text, params);
  }
};

// Extremely basic SQL parser simulator for in-memory mock database operations
const runMockQuery = (sql, params) => {
  const normalized = sql.toLowerCase().replace(/\s+/g, ' ');

  // 1. Fetching categories
  if (normalized.includes('select * from categories') || normalized.includes('from categories')) {
    return { rows: mockStore.categories };
  }

  // 1.5 Fetching material news
  if (normalized.includes('select * from material_news') || normalized.includes('from material_news')) {
    return { rows: mockStore.news };
  }

  // 2. Fetching roles
  if (normalized.includes('select * from roles')) {
    return { rows: mockStore.roles };
  }

  // 3. User checking (Login/Register)
  if (normalized.includes('select * from users where phone =') || normalized.includes('users where phone =')) {
    const phone = params[0];
    const user = mockStore.users.find(u => u.phone === phone);
    return { rows: user ? [user] : [] };
  }
  if (normalized.includes('select * from users where email =') || normalized.includes('users where email =')) {
    const email = params[0];
    const user = mockStore.users.find(u => u.email === email);
    return { rows: user ? [user] : [] };
  }
  if (normalized.includes('select * from users where id =') || normalized.includes('users where id =')) {
    const id = params[0];
    const user = mockStore.users.find(u => u.id === id);
    return { rows: user ? [user] : [] };
  }

  // 4. Products list & filters
  if (normalized.includes('select * from products') || normalized.includes('products p join') || normalized.includes('from products')) {
    let list = mockStore.products.map(p => {
      const supplier = mockStore.suppliers.find(s => s.id === p.supplier_id) || {};
      const category = mockStore.categories.find(c => c.id === p.category_id) || {};
      return {
        ...p,
        company_name: supplier.company_name,
        supplier_location: supplier.location,
        category_name: category.name
      };
    });
    // Handle category filter
    if (params && params.length > 0) {
      // Very basic filtering simulator
      const catId = params.find(p => typeof p === 'number');
      if (catId) {
        list = list.filter(item => item.category_id === catId);
      }
    }
    return { rows: list };
  }

  // 5. Services list
  if (normalized.includes('select * from services') || normalized.includes('from services')) {
    let list = mockStore.services.map(s => {
      const supplier = mockStore.suppliers.find(sup => sup.id === s.supplier_id) || {};
      return {
        ...s,
        company_name: supplier.company_name,
        supplier_location: supplier.location
      };
    });
    return { rows: list };
  }

  // 6. Inquiries list
  if (normalized.includes('select * from inquiries') || normalized.includes('from inquiries')) {
    let list = mockStore.inquiries.map(inq => {
      const buyer = mockStore.users.find(u => u.id === inq.buyer_id || (mockStore.buyers.find(b => b.id === inq.buyer_id) || {}).user_id === u.id) || { name: 'Anonymous Buyer' };
      const supplier = mockStore.suppliers.find(s => s.id === inq.supplier_id) || { company_name: 'Unknown Supplier' };
      return {
        ...inq,
        buyer_name: buyer.name,
        buyer_phone: buyer.phone,
        company_name: supplier.company_name
      };
    });
    
    // Filtering by supplier_id or buyer_id
    if (params && params.length > 0) {
      const idFilter = params[0];
      list = list.filter(item => item.supplier_id === idFilter || item.buyer_id === idFilter);
    }
    return { rows: list };
  }

  // 7. Suppliers
  if (normalized.includes('select * from suppliers') || normalized.includes('from suppliers')) {
    return { rows: mockStore.suppliers };
  }

  // Lookups for buyer/supplier profiles by user_id
  if (normalized.includes('from buyers where user_id =') || normalized.includes('from buyers b where b.user_id =')) {
    const userId = params[0];
    const buyer = mockStore.buyers.find(b => b.user_id === userId);
    return { rows: buyer ? [buyer] : [] };
  }

  if (normalized.includes('from suppliers where user_id =') || normalized.includes('from suppliers s where s.user_id =')) {
    const userId = params[0];
    const supplier = mockStore.suppliers.find(s => s.user_id === userId);
    return { rows: supplier ? [supplier] : [] };
  }

  // Fallback for inserts/updates: Mock writing
  if (normalized.includes('insert into users')) {
    const newUser = {
      id: params[0] || require('crypto').randomUUID(),
      name: params[1],
      email: params[2],
      phone: params[3],
      password_hash: params[4],
      role_id: params[5],
      is_active: true,
      created_at: new Date()
    };
    mockStore.users.push(newUser);
    return { rows: [newUser] };
  }

  if (normalized.includes('insert into suppliers')) {
    let company_name = params[1];
    let business_type = params[2];
    let location = params[3];
    let gst_number = '27AAAAA1111A1Z1';
    let materials_providing = null;
    let is_approved = false; // default to false for approvals

    if (params.length >= 7) {
      gst_number = params[4];
      materials_providing = params[5];
      is_approved = params[6] !== undefined ? params[6] : false;
    } else if (params.length === 5) {
      is_approved = params[4] !== undefined ? params[4] : false;
    }

    const newSup = {
      id: require('crypto').randomUUID(),
      user_id: params[0],
      company_name,
      business_type: business_type || 'Manufacturer',
      description: 'B2B Sourcing Supplier Center.',
      location: location || 'All India',
      gst_number,
      materials_providing,
      website: '',
      logo_url: 'https://images.unsplash.com/photo-1560179707-f14e90ef3623?auto=format&fit=crop&q=80&w=200',
      images: ['https://images.unsplash.com/photo-1590069261209-f8e9b8642343?auto=format&fit=crop&q=80&w=600'],
      is_approved,
      created_at: new Date()
    };
    mockStore.suppliers.push(newSup);
    return { rows: [newSup] };
  }

  if (normalized.includes('insert into buyers')) {
    // INSERT INTO buyers (user_id, location)
    const newBuyer = {
      id: require('crypto').randomUUID(),
      user_id: params[0],
      location: params[1] || 'India',
      preferences: { preferred_categories: [1, 2, 8] },
      created_at: new Date()
    };
    mockStore.buyers.push(newBuyer);
    return { rows: [newBuyer] };
  }

  if (normalized.includes('insert into products')) {
    // INSERT INTO products (id, supplier_id, category_id, name, description, specifications, images, status)
    const newProd = {
      id: params[0],
      supplier_id: params[1],
      category_id: params[2],
      name: params[3],
      description: params[4],
      specifications: typeof params[5] === 'string' ? JSON.parse(params[5]) : (params[5] || {}),
      images: params[6] || [],
      status: 'Approved', // Auto approve in mock mode
      price_per_unit: 420.00,
      unit_type: 'Bag',
      cost_price: 310.00,
      created_at: new Date()
    };
    mockStore.products.push(newProd);
    return { rows: [newProd] };
  }

  if (normalized.includes('insert into services')) {
    // INSERT INTO services (id, supplier_id, category_id, name, description, images, status)
    const newServ = {
      id: params[0],
      supplier_id: params[1],
      category_id: params[2],
      name: params[3],
      description: params[4],
      images: params[5] || [],
      status: 'Approved',
      created_at: new Date()
    };
    mockStore.services.push(newServ);
    return { rows: [newServ] };
  }

  if (normalized.includes('insert into inquiries')) {
    // INSERT INTO inquiries (id, buyer_id, supplier_id, product_id, service_id, title, description, quantity, unit, location, images, status)
    const newInq = {
      id: params[0],
      buyer_id: params[1],
      supplier_id: params[2],
      product_id: params[3],
      service_id: params[4],
      title: params[5],
      description: params[6],
      quantity: params[7],
      unit: params[8] || 'Units',
      location: params[9] || 'India',
      images: params[10] || [],
      status: 'New',
      quoted_price: null,
      delivery_status: 'Pending',
      gst_percent: 18.00,
      created_at: new Date()
    };
    mockStore.inquiries.push(newInq);
    return { rows: [newInq] };
  }

  if (normalized.includes('insert into inquiry_status_logs')) {
    const newLog = {
      id: require('crypto').randomUUID(),
      inquiry_id: params[0],
      status: params[1],
      notes: params[2],
      changed_by_user_id: params[3],
      created_at: new Date()
    };
    mockStore.inquiry_status_logs.push(newLog);
    return { rows: [newLog] };
  }

  if (normalized.includes('insert into notifications')) {
    const newNotif = {
      id: require('crypto').randomUUID(),
      user_id: params[0],
      title: params[1],
      body: params[2],
      payload: typeof params[3] === 'string' ? JSON.parse(params[3]) : (params[3] || {}),
      is_read: false,
      created_at: new Date()
    };
    mockStore.notifications.push(newNotif);
    return { rows: [newNotif] };
  }

  // Update status (Inquiries, Supplier validation, etc)
  if (normalized.includes('update inquiries set status =')) {
    const status = params[0];
    const id = params[1];
    const inq = mockStore.inquiries.find(i => i.id === id);
    if (inq) inq.status = status;
    return { rows: inq ? [inq] : [] };
  }

  if (normalized.includes('update suppliers set is_approved =')) {
    const approved = params[0];
    const id = params[1];
    const sup = mockStore.suppliers.find(s => s.id === id);
    if (sup) sup.is_approved = approved;
    return { rows: sup ? [sup] : [] };
  }

  return { rows: [] };
};

module.exports = {
  query,
  dbMode: () => dbMode,
  mockStore // Export for direct manipulation in controllers if needed
};
