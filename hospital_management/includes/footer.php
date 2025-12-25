</div> <!-- Close container-fluid -->
        </div> <!-- Close content -->
    </div> <!-- Close wrapper -->

    <!-- Bootstrap Bundle with Popper -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
    
    <!-- jQuery (for easier DOM manipulation) -->
    <script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>
    
    <!-- Custom JavaScript -->
    <script src="/hospital_management/assets/js/main.js"></script>
    
    <!-- Page-specific scripts -->
    <?php if (isset($pageScripts)): ?>
        <?php echo $pageScripts; ?>
    <?php endif; ?>
</body>
</html>