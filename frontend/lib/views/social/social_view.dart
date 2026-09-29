import 'package:flutter/material.dart';

class SocialView extends StatelessWidget {
  const SocialView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Community & Challenges'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Feed & Friends'),
              Tab(text: 'Challenges & Badges'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Friends Feed Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            CircleAvatar(child: Text('JD')),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('John Doe', style: TextStyle(fontWeight: FontWeight.bold)),
                                Text('Completed Chest & Triceps • 2h ago',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text('Hit a new PR on Bench Press: 100kg x 5 reps! 🔥💪'),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.thumb_up_alt_outlined),
                              onPressed: () {},
                            ),
                            const Text('12'),
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.mode_comment_outlined),
                              onPressed: () {},
                            ),
                            const Text('3'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Challenges Tab
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Color(0xFF00E676),
                      child: Icon(Icons.emoji_events_rounded, color: Colors.black),
                    ),
                    title: const Text('10k Push-up Monthly Challenge'),
                    subtitle: const Text('Ends in 12 days • 240 participants'),
                    trailing: ElevatedButton(
                      onPressed: () {},
                      child: const Text('Join'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
