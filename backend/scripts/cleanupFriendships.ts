import 'dotenv/config';
import { PrismaClient, FriendshipStatus } from '@prisma/client';

const prisma = new PrismaClient();

const apply = process.argv.includes('--apply');

interface PairRow {
    id: string;
    requesterId: string;
    receiverId: string;
    status: FriendshipStatus;
    createdAt: Date;
    acceptedAt: Date | null;
}

function pairKey(a: string, b: string) {
    return [a, b].sort().join('::');
}

async function main() {
    const rows: PairRow[] = await prisma.friendship.findMany({
        select: {
            id: true,
            requesterId: true,
            receiverId: true,
            status: true,
            createdAt: true,
            acceptedAt: true,
        },
    });

    const byPair = new Map<string, PairRow[]>();
    for (const row of rows) {
        const key = pairKey(row.requesterId, row.receiverId);
        const group = byPair.get(key) || [];
        group.push(row);
        byPair.set(key, group);
    }

    const toDelete: string[] = [];

    for (const group of byPair.values()) {
        if (group.length <= 1) continue;

        const accepted = group.filter((r) => r.status === FriendshipStatus.ACCEPTED);
        const pending = group.filter((r) => r.status === FriendshipStatus.PENDING);
        const others = group.filter(
            (r) => r.status !== FriendshipStatus.ACCEPTED && r.status !== FriendshipStatus.PENDING
        );

        if (accepted.length > 0) {
            const keep =
                accepted.sort(
                    (a, b) => (a.acceptedAt?.getTime() ?? 0) - (b.acceptedAt?.getTime() ?? 0)
                )[0];
            for (const row of group) {
                if (row.id !== keep.id) toDelete.push(row.id);
            }
        } else if (pending.length > 0) {
            const keep = pending.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())[0];
            for (const row of group) {
                if (row.id !== keep.id) toDelete.push(row.id);
            }
        } else {
            const keep = others.sort((a, b) => b.createdAt.getTime() - a.createdAt.getTime())[0];
            for (const row of others) {
                if (row.id !== keep.id) toDelete.push(row.id);
            }
        }
    }

    console.log(`Total friendship rows: ${rows.length}`);
    console.log(`Duplicate/stale rows to delete: ${toDelete.length}`);

    if (!apply) {
        console.log('Dry run. Re-run with --apply to delete these rows.');
        for (const id of toDelete) console.log(`  would delete: ${id}`);
        return;
    }

    let deleted = 0;
    for (const id of toDelete) {
        try {
            await prisma.friendship.delete({ where: { id } });
            deleted++;
        } catch {
            console.warn(`Skipped ${id} (already gone)`);
        }
    }

    console.log(`Deleted ${deleted} rows.`);
}

main()
    .catch((err) => {
        console.error(err);
        process.exit(1);
    })
    .finally(() => prisma.$disconnect());
