import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ticketmaster_api.dart';
import '../services/event_api.dart';

class ExplorePage extends StatefulWidget {
  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  late Future<List<Event>> _futureEvents;
  List<Event> _attendingEvents = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadUserCityAndFetchEvents();
    _loadAttendingEvents();
  }

  Future<void> _loadAttendingEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final snap = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('attendingEvents')
          .get();

      final events = snap.docs.map((d) {
        final data = d.data();
        return Event(
          title: data['title'] ?? '',
          location: data['location'] ?? '',
          date: data['date'] ?? '',
          image: data['image'] ?? '',
          price: data['price'] ?? '',
        );
      }).toList();

      setState(() => _attendingEvents = events);
    } catch (e) {
      print("Error loading attending events: $e");
    }
  }

  Future<void> _saveAttendingEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final userRef = _firestore.collection('users').doc(user.uid);
      final attendingRef = userRef.collection('attendingEvents');

      // Build stable event IDs (title + date)
      final List<String> attendingIds = [];

      for (var event in _attendingEvents) {
        final eventId = "${event.title}_${event.date}".replaceAll(" ", "_");
        attendingIds.add(eventId);

        await attendingRef.doc(eventId).set({
          'title': event.title,
          'location': event.location,
          'date': event.date,
          'image': event.image,
          'price': event.price,
          'savedAt': FieldValue.serverTimestamp(),
        });

        // Also save user under /events/{eventId}/attendingUsers
        await _firestore.collection('events').doc(eventId).set({
          'attendingUsers': FieldValue.arrayUnion([user.uid]),
          'title': event.title,
          'date': event.date,
          'image': event.image,
        }, SetOptions(merge: true));
      }

      await userRef.set({'attending': attendingIds}, SetOptions(merge: true));
    } catch (e) {
      print('Error saving attending events: $e');
    }
  }

  Future<void> _loadUserCityAndFetchEvents() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();

      String city = "Tampa"; // default

      if (doc.exists && doc.data()!.containsKey('location')) {
        final savedLocation = doc.data()!['location'];
        if (savedLocation != null &&
            savedLocation.toString().trim().isNotEmpty) {
          city = savedLocation.toString().trim();
        }
      }

      setState(() {
        _futureEvents = TicketmasterApi.fetchEvents(city: city);
      });
    } catch (e) {
      print("Error loading city: $e");
      setState(() {
        _futureEvents = TicketmasterApi.fetchEvents(city: "Tampa");
      });
    }
  }

  void toggleAttending(Event event) {
    setState(() {
      final existingIndex = _attendingEvents.indexWhere(
        (e) => e.title == event.title && e.date == event.date,
      );

      if (existingIndex >= 0) {
        _attendingEvents.removeAt(existingIndex);
      } else {
        _attendingEvents.add(event);
      }
    });
    _saveAttendingEvents();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchBar(),
              const SizedBox(height: 20),

              // trending nearby
              sectionHeader('Trending Near You'),
              const SizedBox(height: 10),
              FutureBuilder<List<Event>>(
                future: _futureEvents,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('No events found.');
                  }
                  return eventList(snapshot.data!, showAttendingButton: true);
                },
              ),
              const SizedBox(height: 30),

              // mark attending
              sectionHeader('Attending Events'),
              const SizedBox(height: 10),
              _attendingEvents.isEmpty
                  ? const Text('You haven’t marked any events yet.')
                  : eventList(_attendingEvents, showAttendingButton: false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() => const Padding(
    padding: EdgeInsets.only(top: 20),
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: "Find\n",
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
          ),
          TextSpan(
            text: "Nearby Concerts",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF7086F8),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildSearchBar() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Row(
      children: [
        Icon(Icons.search, color: Colors.grey),
        SizedBox(width: 8),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search event..',
              border: InputBorder.none,
            ),
          ),
        ),
        Icon(Icons.tune_rounded, color: Colors.grey),
      ],
    ),
  );

  Widget sectionHeader(String title) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      const Text(
        'See all',
        style: TextStyle(color: Color(0xFF7086F8), fontSize: 14),
      ),
    ],
  );

  Widget eventList(List<Event> events, {required bool showAttendingButton}) =>
      SizedBox(
        height: 250,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];

            return Stack(
              children: [
                Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        child: Image.network(
                          event.image,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    event.location,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  event.date,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              event.price,
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (showAttendingButton)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => toggleAttending(event),
                      child: CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            _attendingEvents.any(
                              (e) =>
                                  e.title == event.title &&
                                  e.date == event.date,
                            )
                            ? const Color(0xFF7086F8)
                            : Colors.blueGrey,
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),

                if (!showAttendingButton)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: GestureDetector(
                      onTap: () => toggleAttending(event),
                      child: const CircleAvatar(
                        radius: 14,
                        backgroundColor: Colors.redAccent,
                        child: Icon(Icons.close, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      );
}
