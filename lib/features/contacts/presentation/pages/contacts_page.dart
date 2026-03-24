import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubit/contact_cubit.dart';
import '../../cubit/contact_state.dart';
import '../../models/contact.dart';
import 'create_contact_page.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ContactCubit(),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Contacts'),
            bottom: const TabBar(
              indicatorColor: Colors.white,
              tabs: [
                Tab(icon: Icon(Icons.person), text: "Customers"),
                Tab(icon: Icon(Icons.store), text: "Vendors"),
              ],
            ),
          ),
          floatingActionButton: Builder(
            builder: (context) => FloatingActionButton(
              onPressed: () {
                final int tabIndex = DefaultTabController.of(context).index;
                final String type = tabIndex == 0 ? 'customer' : 'vendor';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BlocProvider.value(
                      value: context.read<ContactCubit>(),
                      child: CreateContactPage(initialType: type),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add),
            ),
          ),
          body: const TabBarView(
            children: [
              _ContactListTab(type: 'customer'),
              _ContactListTab(type: 'vendor'),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactListTab extends StatefulWidget {
  final String type;
  const _ContactListTab({required this.type});

  @override
  State<_ContactListTab> createState() => _ContactListTabState();
}

class _ContactListTabState extends State<_ContactListTab> {
  @override
  void initState() {
    super.initState();
    context.read<ContactCubit>().fetchContacts(widget.type);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ContactCubit, ContactState>(
      builder: (context, state) {
        if (state is ContactLoading || state is ContactInitial) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is ContactError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.deepPurple, size: 60),
                const SizedBox(height: 16),
                Text(
                  state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.read<ContactCubit>().fetchContacts(widget.type),
                  child: const Text('Retry'),
                )
              ],
            ),
          );
        } else if (state is ContactLoaded) {
          if (state.contacts.isEmpty) {
            return Center(child: Text('No ${widget.type} found.'));
          }
          return RefreshIndicator(
            onRefresh: () async {
              await context.read<ContactCubit>().fetchContacts(widget.type);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: state.contacts.length,
              itemBuilder: (context, index) {
                Contact contact = state.contacts[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        widget.type == 'customer' ? Icons.person : Icons.store,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${contact.email}\n${contact.phone}'),
                    isThreeLine: true,
                    trailing: Text(
                      '${contact.balance.toStringAsFixed(2)}\n${contact.currencyCode}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: contact.balance > 0 ? Colors.green : Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}
