import 'dart:math';

/// Select a random item from a list using weighted probabilities
T weightedRandomChoice<T>(List<T> items, List<double> weights) {
  if (items.isEmpty) {
    throw ArgumentError('Items list cannot be empty');
  }
  
  if (items.length != weights.length) {
    throw ArgumentError('Items and weights must have the same length');
  }
  
  final random = Random();
  final totalWeight = weights.reduce((a, b) => a + b);
  final randomValue = random.nextDouble() * totalWeight;
  
  double cumulativeWeight = 0.0;
  for (int i = 0; i < items.length; i++) {
    cumulativeWeight += weights[i];
    if (randomValue <= cumulativeWeight) {
      return items[i];
    }
  }
  
  // Fallback (should never reach here)
  return items.last;
}

