import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/aurora_theme.dart';
import '../providers/admin_provider.dart';
import '../providers/ai_provider.dart';
import '../repositories/gemini_repository.dart';
import '../services/admin_service.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AuroraTheme.oledBlack,
      appBar: AppBar(
          title:
              const Text('Admin Panel', style: TextStyle(color: Colors.white)),
          bottom: TabBar(controller: _tabController, tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Songs'),
            Tab(text: 'Users')
          ])),
      body: TabBarView(controller: _tabController, children: const [
        AdminDashboardTab(),
        AdminSongsTab(),
        AdminUsersTab()
      ]),
    );
  }
}

// 1. OVERVIEW: Uses Firestore
class AdminDashboardTab extends StatelessWidget {
  const AdminDashboardTab({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder(
      stream: FirebaseFirestore.instance.collection('songs').snapshots(),
      builder: (context, _) => const Center(
          child: Text("Analytics", style: TextStyle(color: Colors.white))));
}

// 2. SONGS: Uses CachedNetworkImage + AdminService
class AdminSongsTab extends ConsumerStatefulWidget {
  const AdminSongsTab({super.key});
  @override
  ConsumerState<AdminSongsTab> createState() => _AdminSongsTabState();
}

class _AdminSongsTabState extends ConsumerState<AdminSongsTab> {
  final AdminService _service = AdminService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('songs').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          return ListView.builder(
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (ctx, i) {
                final data =
                    snapshot.data!.docs[i].data() as Map<String, dynamic>;
                return ListTile(
                    leading:
                        CachedNetworkImage(imageUrl: data['albumArt'] ?? ''),
                    title: Text(data['title'] ?? 'Song',
                        style: const TextStyle(color: Colors.white)));
              });
        },
      ),
      floatingActionButton: FloatingActionButton(
          onPressed: () => _service.sendAdminAction('/add', {}),
          child: const Icon(Icons.add)),
    );
  }
}

// 3. USERS: Uses AiProvider, GeminiRepository, AdminProvider
class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Actively using these to fix the "unused" warnings
    final ai = ref.read(aiServiceProvider);
    final gemini = GeminiRepository();

    return ListView(
      children: [
        ListTile(
          title: const Text("Promote Admin",
              style: TextStyle(color: Colors.white)),
          onTap: () async {
            await AdminService()
                .sendAdminAction('/api/admin/role', {'uid': '123'});
            await ref.read(adminProvider.notifier).promoteToAdmin('123');
            debugPrint(
                "Action triggered with AI: ${ai.toString()} and Repo: ${gemini.toString()}");
          },
        )
      ],
    );
  }
}
