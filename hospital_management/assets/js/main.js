/**
 * Hospital Management System - Main JavaScript
 */

$(document).ready(function() {
    // Sidebar toggle
    $('#sidebarCollapse').on('click', function() {
        $('#sidebar').toggleClass('collapsed');
    });

    // Load notifications on page load
    loadNotifications();
    
    // Refresh notifications every 30 seconds
    setInterval(loadNotifications, 30000);

    // Auto-hide alerts after 5 seconds
    setTimeout(function() {
        $('.alert').fadeOut('slow');
    }, 5000);

    // Initialize tooltips
    var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    var tooltipList = tooltipTriggerList.map(function(tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });

    // Initialize popovers
    var popoverTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="popover"]'));
    var popoverList = popoverTriggerList.map(function(popoverTriggerEl) {
        return new bootstrap.Popover(popoverTriggerEl);
    });

    // Confirm delete actions
    $('.btn-delete').on('click', function(e) {
        if (!confirm('Are you sure you want to delete this item?')) {
            e.preventDefault();
        }
    });

    // Form validation
    $('form.needs-validation').on('submit', function(e) {
        if (!this.checkValidity()) {
            e.preventDefault();
            e.stopPropagation();
        }
        $(this).addClass('was-validated');
    });
});

/**
 * Load notifications via AJAX
 */
function loadNotifications() {
    $.ajax({
        url: '/hospital_management/api/notifications.php',
        method: 'GET',
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                updateNotificationBadge(response.unread_count);
                displayNotifications(response.notifications);
            }
        },
        error: function() {
            console.error('Failed to load notifications');
        }
    });
}

/**
 * Update notification badge count
 */
function updateNotificationBadge(count) {
    const badge = $('#notificationCount');
    if (count > 0) {
        badge.text(count).show();
    } else {
        badge.hide();
    }
}

/**
 * Display notifications in dropdown
 */
function displayNotifications(notifications) {
    const list = $('#notificationList');
    list.empty();
    
    if (notifications.length === 0) {
        list.append('<li><span class="dropdown-item-text text-muted">No new notifications</span></li>');
        return;
    }
    
    notifications.forEach(function(notif) {
        const time = formatTimeAgo(notif.created_at);
        const readClass = notif.is_read ? 'text-muted' : 'fw-bold';
        
        const notificationItem = $(`
            <li>
                <div class="dropdown-item ${readClass}" style="cursor: default;">
                    <small class="text-muted d-block">${time}</small>
                    ${notif.content}
                </div>
            </li>
        `);
        
        // Prevent clicking on individual notifications
        notificationItem.find('.dropdown-item').on('click', function(e) {
            e.preventDefault();
            e.stopPropagation();
            return false;
        });
        
        list.append(notificationItem);
    });
    
    list.append('<li><hr class="dropdown-divider"></li>');
    list.append('<li><a class="dropdown-item text-center" href="#" id="markAllRead">Mark all as read</a></li>');
    
    // Handle mark all as read
    $('#markAllRead').on('click', function(e) {
        e.preventDefault();
        markAllNotificationsRead();
    });
}

/**
 * Format timestamp to relative time
 */
function formatTimeAgo(timestamp) {
    const now = new Date();
    const time = new Date(timestamp);
    const diff = Math.floor((now - time) / 1000); // seconds
    
    if (diff < 60) return 'Just now';
    if (diff < 3600) return Math.floor(diff / 60) + ' minutes ago';
    if (diff < 86400) return Math.floor(diff / 3600) + ' hours ago';
    return Math.floor(diff / 86400) + ' days ago';
}

/**
 * Mark all notifications as read
 */
function markAllNotificationsRead() {
    $.ajax({
        url: '/hospital_management/api/notifications.php',
        method: 'POST',
        data: { action: 'mark_all_read' },
        dataType: 'json',
        success: function(response) {
            if (response.success) {
                loadNotifications();
            }
        }
    });
}

/**
 * Show loading spinner
 */
function showLoading() {
    $('body').append(`
        <div class="spinner-overlay">
            <div class="spinner-border text-light" role="status">
                <span class="visually-hidden">Loading...</span>
            </div>
        </div>
    `);
}

/**
 * Hide loading spinner
 */
function hideLoading() {
    $('.spinner-overlay').remove();
}

/**
 * Show toast notification
 */
function showToast(message, type = 'info') {
    const toast = $(`
        <div class="toast align-items-center text-white bg-${type} border-0 position-fixed bottom-0 end-0 m-3" role="alert" style="z-index: 9999;">
            <div class="d-flex">
                <div class="toast-body">
                    ${message}
                </div>
                <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
            </div>
        </div>
    `);
    
    $('body').append(toast);
    const bsToast = new bootstrap.Toast(toast[0]);
    bsToast.show();
    
    setTimeout(function() {
        toast.remove();
    }, 5000);
}

/**
 * Format currency (Vietnamese Dong)
 */
function formatCurrency(amount) {
    return new Intl.NumberFormat('vi-VN', {
        style: 'currency',
        currency: 'VND'
    }).format(amount);
}

/**
 * Format date
 */
function formatDate(dateString) {
    const date = new Date(dateString);
    return date.toLocaleDateString('vi-VN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit'
    });
}

/**
 * Format datetime
 */
function formatDateTime(dateString) {
    const date = new Date(dateString);
    return date.toLocaleString('vi-VN', {
        year: 'numeric',
        month: '2-digit',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit'
    });
}

/**
 * Debounce function for search inputs
 */
function debounce(func, wait) {
    let timeout;
    return function executedFunction(...args) {
        const later = () => {
            clearTimeout(timeout);
            func(...args);
        };
        clearTimeout(timeout);
        timeout = setTimeout(later, wait);
    };
}