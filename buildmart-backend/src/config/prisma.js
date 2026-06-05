const { PrismaClient } = require('@prisma/client');
const { PrismaPg } = require('@prisma/adapter-pg');
const { Pool } = require('pg');
require('dotenv').config();

const connectionString = process.env.DATABASE_URL || '';

let prisma;

const isSSLNeeded = connectionString.includes('neon.tech') || connectionString.includes('sslmode=require');
const pool = new Pool({
  connectionString: connectionString || `postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT || 5432}/${process.env.DB_NAME}`,
  connectionTimeoutMillis: 5000,
  ssl: isSSLNeeded ? { rejectUnauthorized: false } : undefined
});

const adapter = new PrismaPg(pool);
prisma = new PrismaClient({ adapter });

module.exports = prisma;
