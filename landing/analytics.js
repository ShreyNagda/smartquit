const firebaseConfig = {
  apiKey: "AIzaSyAvQqSH9sUyHqC19W0eXyjGFqDgAowFztM",
  authDomain: "smoking-cessation-78e14.firebaseapp.com",
  projectId: "smoking-cessation-78e14",
  storageBucket: "smoking-cessation-78e14.firebasestorage.app",
  messagingSenderId: "242383778526",
  appId: "1:242383778526:web:680c935f209e016b39c84f"
};

firebase.initializeApp(firebaseConfig);
const db = firebase.firestore();

// Function to fetch total users and their profile creation dates
async function getUsersData() {
  try {
    const usersSnapshot = await db.collection("users").get();
    console.log("Fetched users:", usersSnapshot.size);

    const users = [];
    const profileCreationDates = [];

    usersSnapshot.forEach(doc => {
      const userData = doc.data();
      users.push({
        id: doc.id,
        ...userData
      });

      // Extract profile creation date
      if (userData.createdAt) {
        const createdAt = userData.createdAt.toDate ? userData.createdAt.toDate() : new Date(userData.createdAt);
        profileCreationDates.push(createdAt);
      }
    });

    return {
      totalUsers: users.length,
      users: users,
      profileCreationDates: profileCreationDates
    };
  } catch (error) {
    console.error("Error fetching users:", error);
    return { totalUsers: 0, users: [], profileCreationDates: [] };
  }
}

// Function to fetch all journal entries across users
async function getAllJournalEntries() {
  try {
    const journalEntries = [];

    // Get all users first
    const usersSnapshot = await db.collection("users").get();

    // For each user, get their journal entries
    const promises = [];
    usersSnapshot.forEach(userDoc => {
      const promise = db.collection("users").doc(userDoc.id).collection("journal").get()
        .then(journalSnapshot => {
          console.log(`Fetched journal entries for user ${userDoc.id}:`, journalSnapshot.size);
          journalSnapshot.forEach(journalDoc => {
            journalEntries.push({
              id: journalDoc.id,
              userId: userDoc.id,
              ...journalDoc.data()
            });
          });
        });
      promises.push(promise);
    });

    await Promise.all(promises);
    console.log("Fetched journal entries:", journalEntries.length);

    return journalEntries;
  } catch (error) {
    console.error("Error fetching journal entries:", error);
    return [];
  }
}

// Function to get journal breakdown by type
async function getJournalBreakdown() {
  try {
    const journalEntries = await getAllJournalEntries();
    const counts = { craving: 0, relapse: 0, near_miss: 0, milestone: 0 };

    journalEntries.forEach(entry => {
      const type = entry.event_type?.toLowerCase() || entry.type?.toLowerCase();
      if (counts.hasOwnProperty(type)) {
        counts[type]++;
      }
    });

    return {
      counts: counts,
      totalEntries: journalEntries.length,
      entries: journalEntries
    };
  } catch (error) {
    console.error("Error getting journal breakdown:", error);
    return { counts: { craving: 0, relapse: 0, near_miss: 0, milestone: 0 }, totalEntries: 0, entries: [] };
  }
}

// Function to get analytics summary
async function getAnalyticsSummary() {
  try {
    const [usersData, journalData] = await Promise.all([
      getUsersData(),
      getJournalBreakdown()
    ]);

    return {
      users: usersData,
      journal: journalData,
      summary: {
        totalUsers: usersData.totalUsers,
        totalJournalEntries: journalData.totalEntries,
        averageEntriesPerUser: usersData.totalUsers > 0 ? (journalData.totalEntries / usersData.totalUsers).toFixed(2) : 0
      }
    };
  } catch (error) {
    console.error("Error getting analytics summary:", error);
    return null;
  }
}

// Function to update dashboard with real data
async function updateDashboard() {
  try {
    const analytics = await getAnalyticsSummary();

    if (analytics) {
      // Update user stats
      const totalUsersElement = document.getElementById('totalUsers');
      if (totalUsersElement) {
        totalUsersElement.textContent = analytics.summary.totalUsers;
      }

      // Update journal stats
      const totalEntriesElement = document.getElementById('totalEntries');
      if (totalEntriesElement) {
        totalEntriesElement.textContent = analytics.summary.totalJournalEntries;
      }

      // Update average entries
      const avgEntriesElement = document.getElementById('avgEntries');
      if (avgEntriesElement) {
        avgEntriesElement.textContent = analytics.summary.averageEntriesPerUser;
      }

      console.log("Dashboard updated with real data:", analytics.summary);
    }
  } catch (error) {
    console.error("Error updating dashboard:", error);
  }
}

async function renderCharts() {
  const data = await getJournalBreakdown();
  const ctx = document.getElementById('journalChart');

  if (ctx) {
    new Chart(ctx.getContext('2d'), {
      type: 'doughnut',
      data: {
        labels: ['Cravings', 'Relapses', 'Near Miss', 'Milestones'],
        datasets: [{
          data: [data.counts.craving, data.counts.relapse, data.counts.near_miss, data.counts.milestone],
          backgroundColor: ['#e07a5f', '#dc3545', '#ffc107', '#5b7553']
        }]
      },
      options: {
        responsive: true,
        plugins: {
          legend: {
            position: 'bottom'
          },
          title: {
            display: true,
            text: `Journal Entries Breakdown (Total: ${data.totalEntries})`
          }
        }
      }
    });
  }
}

// Initialize dashboard
async function initializeDashboard() {
  console.log("Initializing analytics dashboard...");
  await updateDashboard();
  await renderCharts();
  console.log("Dashboard initialization complete.");
}

// Start the dashboard when page loads
initializeDashboard();
