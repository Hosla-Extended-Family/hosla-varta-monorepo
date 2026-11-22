import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const TAGS = [
    { name: 'EMERGENCY', priority: 100 },
    { name: 'HEALTH', priority: 80 },
    { name: 'ANNOUNCEMENT', priority: 60 },
    { name: 'GENERAL', priority: 40 },
    { name: 'SOCIAL', priority: 20 },
    { name: 'DEFAULT', priority: 10 },
];

async function main() {
    console.log('Seeding tags...');
    for (const tag of TAGS) {
        await prisma.tag.upsert({
            where: { name: tag.name },
            update: { priority: tag.priority },
            create: {
                name: tag.name,
                priority: tag.priority,
            },

        });
    }
    console.log('Tags seeded successfully.');
}

main()
    .catch((e) => {
        console.error(e);
        process.exit(1);
    })
    .finally(async () => {
        await prisma.$disconnect();
    });
