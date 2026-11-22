import { PrismaClient, PostStatus, PostVisibility } from '@prisma/client';

const prisma = new PrismaClient();

const tagsList = [
    'Emergency', 'Health', 'Daily Tips', 'Events', 'News',
    'Family', 'Spiritual', 'Hobbies', 'Nature', 'Morning',
    'Books', 'History', 'Memories', 'Food', 'Travel'
];

const naturalTexts = [
    "Does anyone know a good home remedy for joint pain? My knees have been hurting lately.",
    "Had a wonderful time at the park today with my grandchildren. The weather was perfect!",
    "I made Gajar ka Halwa today. It turned out delicious. Let me know if anyone wants the recipe.",
    "Is there a satsang happening nearby this weekend? I would love to join.",
    "Just finished reading 'The Guide' by R.K. Narayan. Such a classic!",
    "Feeling a bit lonely today. Would love to chat with someone.",
    "Good morning everyone! Wishing you all a blessed and happy day.",
    "Can someone recommend a good orthopedic doctor in the city?",
    "Enjoying a hot cup of chai while watching the rain. Thinking of old times.",
    "Happy Birthday to my dear friend Sharma ji! May you have a long flexibility life.",
    "I am looking for a yoga group for seniors. Please suggest.",
    "My son sent me this beautiful photo from his trip to Switzerland.",
    "Remembering the old days when we used to listen to the radio together.",
    "Made some pickles today. Nothing beats the taste of homemade mango pickle!",
    "Be careful of the scam calls going around. My neighbor got a call yesterday asking for bank details.",
    "What is the best way to keep blood pressure in check naturally?",
    "Looking forward to the community gathering next Sunday.",
    "Does anyone want to exchange old books? I have a collection of Hindi novels.",
    "Proud of my granddaughter for scoring top marks in her exams!",
    "Has anyone tried the new ayurvedic clinic near the market?",
    "Let's organize a potluck lunch for next month. What do you say?",
    "Listening to old Kishore Kumar songs. Pure nostalgia.",
    "Please pray for my wife's speedy recovery.",
    "Grateful for the little things in life. Health is wealth.",
    "Technology is confusing sometimes. Can someone help me change my profile picture?",
    "Found an old photo album today. So many beautiful memories.",
    "Stay hydrated everyone! The heat is increasing.",
    "Anyone interested in a morning walk group?",
    "Just learned how to make video calls. It's amazing to see my kids face to face.",
    "Life is beautiful when you have good friends around."
];

const imageUrls = [
    "https://picsum.photos/seed/n1/600/400",
    "https://picsum.photos/seed/n2/600/400",
    "https://picsum.photos/seed/n3/600/400",
    "https://picsum.photos/seed/n4/600/400",
    "https://picsum.photos/seed/n5/600/400",
    "https://picsum.photos/seed/n6/600/400",
    "https://picsum.photos/seed/n7/600/400",
    "https://picsum.photos/seed/n8/600/400",
    "https://picsum.photos/seed/n9/600/400",
    "https://picsum.photos/seed/n10/600/400",
    "https://picsum.photos/seed/n11/600/400",
    "https://picsum.photos/seed/n12/600/400",
];

function getRandomItem(arr: any[]) {
    return arr[Math.floor(Math.random() * arr.length)];
}

function getRandomInt(min: number, max: number) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
}

async function main() {
    console.log('Starting natural language bulk seeding...');

    const users = await prisma.user.findMany();
    if (users.length === 0) {
        console.log('No users found. Run standard seed first.');
        return;
    }

    const numPosts = 200;
    console.log(`Creating ${numPosts} posts...`);

    for (let i = 0; i < numPosts; i++) {
        const author = getRandomItem(users);
        const hasImage = Math.random() > 0.6; // 40% chance of image
        const numTags = getRandomInt(1, 2);
        const selectedTags = [];

        for (let j = 0; j < numTags; j++) {
            selectedTags.push(getRandomItem(tagsList));
        }

        const uniqueTags = [...new Set(selectedTags)];
        const textContent = getRandomItem(naturalTexts);

        // Sometimes combine two sentences
        const bodyToCheck = Math.random() > 0.7 ? `${textContent} ${getRandomItem(naturalTexts)}` : textContent;

        const post = await prisma.post.create({
            data: {
                authorId: author.id,
                title: null, // Natural posts often don't have titles like blog posts
                body: bodyToCheck,
                mediaUrls: hasImage ? [getRandomItem(imageUrls)] : [],
                status: PostStatus.PUBLISHED,
                visibility: PostVisibility.PUBLIC,
                tags: {
                    connectOrCreate: uniqueTags.map(tag => ({
                        where: { name: tag },
                        create: { name: tag }
                    }))
                }
            }
        });
        // console.log(`Created Post ${post.id} by ${author.name}`);

        // Likes
        const numLikes = getRandomInt(0, 25);
        const likers = new Set();
        while (likers.size < numLikes && likers.size < users.length) {
            likers.add(getRandomItem(users));
        }

        for (const liker of likers) {
            await prisma.like.create({
                data: {
                    postId: post.id,
                    userId: (liker as any).id
                }
            }).catch(() => { });
        }

        // Comments
        const numComments = getRandomInt(0, 8);
        for (let k = 0; k < numComments; k++) {
            const commenter = getRandomItem(users);
            const commentTexts = ["Great!", "Very true.", "Thanks for sharing.", "Wow!", "Agree.", "Beautiful.", "Identify this please?", "Nice."];

            const comment = await prisma.comment.create({
                data: {
                    postId: post.id,
                    userId: commenter.id,
                    content: getRandomItem(commentTexts),
                }
            });

            // Comment Like
            if (Math.random() > 0.6) {
                const commentLiker = getRandomItem(users);
                await prisma.commentLike.create({
                    data: {
                        commentId: comment.id,
                        userId: commentLiker.id
                    }
                }).catch(() => { });
            }

            // Reply
            if (Math.random() > 0.8) {
                await prisma.comment.create({
                    data: {
                        postId: post.id,
                        userId: author.id,
                        content: "Thanks!",
                        parentId: comment.id
                    }
                });
            }
        }

        if (i % 20 === 0) console.log(`Created ${i} posts...`);
    }

    console.log('Natural language bulk seeding completed.');
}

main()
    .then(async () => {
        await prisma.$disconnect();
    })
    .catch(async (e) => {
        console.error(e);
        await prisma.$disconnect();
        process.exit(1);
    });
