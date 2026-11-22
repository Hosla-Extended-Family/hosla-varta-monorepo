import { PrismaClient, PostStatus, PostVisibility, FriendshipStatus, ProfileVisibility, Gender } from '@prisma/client';

const prisma = new PrismaClient();

async function main() {
    console.log('Starting seed...');

    // 1. Create Default Admin
    const adminPhone = process.env.DEFAULT_ADMIN_PHONE || '+919999999999';
    const adminName = process.env.DEFAULT_ADMIN_NAME || 'System Admin';

    let admin = await prisma.user.findUnique({
        where: { phone: adminPhone },
    });

    if (!admin) {
        admin = await prisma.user.create({
            data: {
                phone: adminPhone,
                name: adminName,
                role: 'ADMIN',
            },
        });
        console.log('Default admin created.');
    } else {
        console.log('Default admin already exists.');
    }

    // 2. Create Test Users
    const usersData = [
        {
            phone: '+919876543210',
            name: 'Ramesh Gupta',
            bio: 'Love gardening and morning walks.',
            dateOfBirth: new Date('1955-05-15'),
            gender: Gender.MALE,
            profileVisibility: ProfileVisibility.PUBLIC,
        },
        {
            phone: '+919876543211',
            name: 'Sunita Sharma',
            bio: 'Retired teacher. Avid reader.',
            dateOfBirth: new Date('1960-08-20'),
            gender: Gender.FEMALE,
            profileVisibility: ProfileVisibility.PUBLIC,
        },
        {
            phone: '+919876543212',
            name: 'Amit Verma',
            bio: 'Enjoying life and music.',
            dateOfBirth: new Date('1958-12-10'),
            gender: Gender.MALE,
            profileVisibility: ProfileVisibility.FRIENDS,
        },
    ];

    const users = [];
    for (const userData of usersData) {
        let user = await prisma.user.findUnique({
            where: { phone: userData.phone },
        });

        if (!user) {
            user = await prisma.user.create({
                data: userData,
            });
            console.log(`Created user: ${user.name}`);
        } else {
            console.log(`User already exists: ${user.name}`);
        }
        users.push(user);
    }

    const [ramesh, sunita, amit] = users;

    // 3. Create Friendships (Ramesh <-> Sunita)
    const friendship = await prisma.friendship.findUnique({
        where: {
            requesterId_receiverId: {
                requesterId: ramesh.id,
                receiverId: sunita.id,
            },
        },
    });

    if (!friendship) {
        await prisma.friendship.create({
            data: {
                requesterId: ramesh.id,
                receiverId: sunita.id,
                status: FriendshipStatus.ACCEPTED,
                acceptedAt: new Date(),
            },
        });
        console.log('Friendship created: Ramesh <-> Sunita');

        // Also create the reverse record if your logic requires it (though schema usually handles one way or unique constraint)
        // Schema has @@unique([requesterId, receiverId]), so strict direction.
        // Usually apps check OR condition.
    }

    // 4. Create Posts

    // Ramesh's Public Post
    const rameshPost = await prisma.post.create({
        data: {
            authorId: ramesh.id,
            body: 'Good morning everyone! The flowers in my garden are blooming beautifully today.',
            status: PostStatus.PUBLISHED,
            visibility: PostVisibility.PUBLIC,
            title: 'Morning Vibes',
        },
    });
    console.log('Created post for Ramesh');

    // Sunita's Public Post
    await prisma.post.create({
        data: {
            authorId: sunita.id,
            body: 'Just finished a wonderful book on Indian history. Highly recommended!',
            status: PostStatus.PUBLISHED,
            visibility: PostVisibility.PUBLIC,
            title: 'Book Recommendation',
        },
    });
    console.log('Created post for Sunita');

    // Amit's Friends-Only Post (Visible only to friends? Amit has no friends yet in this seed but let's make it friends only)
    await prisma.post.create({
        data: {
            authorId: amit.id,
            body: 'Family gathering photos...',
            status: PostStatus.PUBLISHED,
            visibility: PostVisibility.FRIENDS,
        },
    });
    console.log('Created friends-only post for Amit');

    // 5. Interactions

    // Sunita likes Ramesh's post
    await prisma.like.create({
        data: {
            postId: rameshPost.id,
            userId: sunita.id,
        },
    });
    console.log('Sunita liked Ramesh\'s post');

    // Amit likes Ramesh's post
    await prisma.like.create({
        data: {
            postId: rameshPost.id,
            userId: amit.id,
        },
    });
    console.log('Amit liked Ramesh\'s post');

    // Amit comments on Ramesh's post
    const comment = await prisma.comment.create({
        data: {
            postId: rameshPost.id,
            userId: amit.id,
            content: 'Beautiful flowers, Ramesh ji!',
        },
    });
    console.log('Amit commented on Ramesh\'s post');

    // Ramesh replies to Amit's comment
    await prisma.comment.create({
        data: {
            postId: rameshPost.id,
            userId: ramesh.id,
            content: 'Thank you Amit!',
            parentId: comment.id,
        },
    });
    console.log('Ramesh replied to Amit');

    // Sunita likes Amit's comment
    await prisma.commentLike.create({
        data: {
            commentId: comment.id,
            userId: sunita.id,
        },
    });
    console.log('Sunita liked Amit\'s comment');

    console.log('Seeding completed successfully.');
}

main()
    .then(async () => {
        await prisma.$disconnect();
    })
    .catch(async (e) => {
        console.error('Error seeding database:', e);
        await prisma.$disconnect();
        process.exit(1);
    });
