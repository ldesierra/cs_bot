// Mark as Viewed functionality for search items
document.addEventListener('DOMContentLoaded', function() {
  // Handle mark as viewed form submissions
  document.addEventListener('submit', function(e) {
    if (e.target.classList.contains('mark-as-viewed-form')) {
      e.preventDefault();

      const form = e.target;
      const itemId = form.dataset.itemId;
      const itemElement = document.getElementById(`item-${itemId}`);
      const submitButton = form.querySelector('input[type="submit"]`);

      // Disable button and show loading state
      submitButton.disabled = true;
      submitButton.value = 'Marking...';
      submitButton.classList.add('opacity-50');

      // Submit form via fetch
      fetch(form.action, {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        },
        body: new FormData(form)
      })
      .then(response => response.json())
      .then(data => {
        if (data.status === 'success') {
          // Update the UI to show item as viewed
          itemElement.classList.remove('bg-gray-900');
          itemElement.classList.add('bg-gray-800', 'border-gray-700', 'opacity-60');

          // Update text colors
          const titleElement = itemElement.querySelector('h3');
          if (titleElement) {
            titleElement.classList.remove('text-white');
            titleElement.classList.add('text-gray-400');
          }

          // Update all text spans
          const textSpans = itemElement.querySelectorAll('span:not(.bg-):not(.text-gray-400)');
          textSpans.forEach(span => {
            if (span.classList.contains('text-white')) {
              span.classList.remove('text-white');
              span.classList.add('text-gray-500');
            }
          });

          // Replace form with viewed button
          const buttonContainer = form.parentElement;
          buttonContainer.innerHTML = '<button class="bg-gray-500 text-white text-sm font-medium py-2 px-3 rounded cursor-not-allowed" disabled>✓ Viewed</button>';

          // Add viewed badge
          const badgeContainer = itemElement.querySelector('.flex.items-center.space-x-4');
          if (badgeContainer) {
            const viewedBadge = document.createElement('span');
            viewedBadge.className = 'bg-green-600 text-white px-3 py-1 rounded-full text-sm font-bold uppercase tracking-wide';
            viewedBadge.textContent = '✓ Viewed';
            badgeContainer.appendChild(viewedBadge);
          }

          console.log('Item marked as viewed successfully');
        } else {
          console.error('Error marking item as viewed:', data.message);
          alert('Error marking item as viewed: ' + data.message);

          // Reset button
          submitButton.disabled = false;
          submitButton.value = 'Mark as Viewed';
          submitButton.classList.remove('opacity-50');
        }
      })
      .catch(error => {
        console.error('Network error:', error);
        alert('Network error occurred. Please try again.');

        // Reset button
        submitButton.disabled = false;
        submitButton.value = 'Mark as Viewed';
        submitButton.classList.remove('opacity-50');
      });
    }
  });
});
