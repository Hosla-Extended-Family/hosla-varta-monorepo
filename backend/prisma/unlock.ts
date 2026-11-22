import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Releasing locks...');
    try {
        await prisma.$executeRawUnsafe('SELECT pg_advisory_unlock_all();');
        console.log('Locks released.');
    } catch (error) {
        console.error('Failed to release locks:', error);
    } finally {
        await prisma.$disconnect();
    }
}

main();
