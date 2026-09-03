const translations = {
    es: {
        // General
        app_name: 'RustDesk Manager',
        save: 'Guardar',
        cancel: 'Cancelar',
        delete: 'Eliminar',
        edit: 'Editar',
        close: 'Cerrar',
        loading: 'Cargando...',
        error: 'Error',
        success: 'Éxito',
        confirm: 'Confirmar',
        yes: 'Sí',
        no: 'No',

        // Sidebar
        all_devices: 'Todos los equipos',
        unassigned: 'Sin clasificar',
        no_group: 'Sin grupo',
        categories: 'Categorías',
        no_category: 'Sin categoría',
        add_group: 'Añadir grupo',
        new_device: 'Nuevo Equipo',
        settings: 'Ajustes',
        coffee_link: 'Invita un café al desarrollador',

        // Search
        search_placeholder: 'Buscar equipos...',
        search_results: 'Resultados',
        no_results: 'No se encontraron equipos',

        // Device card
        devices: 'equipos',
        view_password: 'Ver clave',
        no_password: 'Sin contraseña',
        connect: 'Conectar',
        file_transfer: 'Transferir archivos',
        connecting: 'Conectando...',
        opening_transfer: 'Abriendo transferencia de archivos...',

        // Device modal
        new_device_title: 'Nuevo Equipo',
        edit_device_title: 'Editar Equipo',
        device_name: 'Nombre',
        device_name_placeholder: 'Ej: Oficina Principal',
        rustdesk_id: 'ID de RustDesk',
        rustdesk_id_placeholder: 'Ej: 123456789',
        password: 'Contraseña',
        password_placeholder: 'Contraseña de acceso',
        group: 'Grupo',
        description: 'Descripción',
        description_placeholder: 'Notas adicionales...',
        color: 'Color',
        save_current_color: 'Guardar color actual como predefinido',
        os_type: 'Sistema operativo',
        os_type_placeholder: 'Sin especificar',
        name_id_required: 'Nombre e ID son obligatorios',
        device_created: 'Equipo creado',
        device_updated: 'Equipo actualizado',
        device_deleted: 'Equipo eliminado',
        delete_device_confirm: '¿Eliminar este equipo?',
        device_exists_unassigned: 'Este ID ya existe en "Sin clasificar". Edítalo desde allí para asignarle grupo.',

        // Group modal
        new_group_title: 'Nuevo Grupo',
        edit_group_title: 'Editar Grupo',
        group_name: 'Nombre',
        group_name_placeholder: 'Ej: Oficina Madrid',
        group_category: 'Categoría',
        name_required: 'El nombre es obligatorio',
        group_created: 'Grupo creado',
        group_updated: 'Grupo actualizado',
        group_deleted: 'Grupo eliminado',
        delete_group_confirm: '¿Eliminar este grupo? Los equipos no se eliminarán.',

        // Category modal
        new_category_title: 'Nueva Categoría',
        edit_category_title: 'Editar Categoría',
        category_name: 'Nombre',
        category_name_placeholder: 'Ej: Clientes',
        category_created: 'Categoría creada',
        category_updated: 'Categoría actualizada',
        category_deleted: 'Categoría eliminada',
        delete_category_confirm: '¿Eliminar esta categoría? Los grupos quedarán sin categoría.',

        // Settings
        settings_title: 'Ajustes',
        api_server: 'Servidor API',
        server_url: 'URL del servidor',
        server_url_placeholder: 'https://servidor:21114',
        username: 'Usuario',
        username_placeholder: 'admin',
        password_settings: 'Contraseña',
        password_keep_placeholder: 'Dejar vacío para mantener',
        password_new_placeholder: 'Escribe la contraseña',
        password_hint: 'Contraseña guardada. Escribe para cambiarla.',
        rustdesk_key: 'Key RustDesk',
        rustdesk_key_placeholder: 'ABCD1234...',
        test_connection: 'Probar conexión',
        connection_success: 'Conexión exitosa',
        connection_error: 'Error de conexión',

        sync_section: 'Sincronización',
        auto_sync: 'Sincronización automática',
        sync_interval: 'Intervalo (segundos)',

        rustdesk_section: 'RustDesk',
        default_password: 'Contraseña por defecto',
        default_password_placeholder: 'Contraseña para nuevos equipos',

        language_section: 'Idioma',
        language: 'Idioma de la aplicación',

        import_export_section: 'Importar / Exportar',
        export_data: 'Exportar datos',
        export_data_desc: 'Descargar base de datos y configuración',
        import_data: 'Importar datos',
        import_data_desc: 'Restaurar desde archivo de respaldo',
        export_success: 'Datos exportados correctamente',
        import_success: 'Datos importados correctamente. Reiniciando...',
        import_error: 'Error al importar datos',
        select_backup_file: 'Selecciona archivo de respaldo (.zip)',

        settings_saved: 'Configuración guardada',
        settings_save_error: 'Error al guardar',

        // Status
        status_updated: 'Estado actualizado desde el servidor',
        status_update_error: 'Error actualizando estado',
        status_online: 'Online',
        status_offline: 'Offline',
        status_unknown: 'Desconocido',
        click_to_change: 'Clic para cambiar',

        // Sync
        sync_complete: 'Todo sincronizado',
        new_devices_imported: 'nuevos equipos importados',
        new_device_notification: 'Nuevo equipo',

        // Table headers
        col_name: 'Nombre',
        col_id: 'ID',
        col_group: 'Grupo',
        col_os: 'SO',
        col_description: 'Descripción',
        col_actions: 'Acciones',

        // Theme
        toggle_theme: 'Cambiar tema',
        refresh: 'Actualizar estado'
    },

    en: {
        // General
        app_name: 'RustDesk Manager',
        save: 'Save',
        cancel: 'Cancel',
        delete: 'Delete',
        edit: 'Edit',
        close: 'Close',
        loading: 'Loading...',
        error: 'Error',
        success: 'Success',
        confirm: 'Confirm',
        yes: 'Yes',
        no: 'No',

        // Sidebar
        all_devices: 'All devices',
        unassigned: 'Unassigned',
        no_group: 'No group',
        categories: 'Categories',
        no_category: 'No category',
        add_group: 'Add group',
        new_device: 'New Device',
        settings: 'Settings',
        coffee_link: 'Buy the developer a coffee',

        // Search
        search_placeholder: 'Search devices...',
        search_results: 'Results',
        no_results: 'No devices found',

        // Device card
        devices: 'devices',
        view_password: 'Show key',
        no_password: 'No password',
        connect: 'Connect',
        file_transfer: 'File transfer',
        connecting: 'Connecting...',
        opening_transfer: 'Opening file transfer...',

        // Device modal
        new_device_title: 'New Device',
        edit_device_title: 'Edit Device',
        device_name: 'Name',
        device_name_placeholder: 'Ex: Main Office',
        rustdesk_id: 'RustDesk ID',
        rustdesk_id_placeholder: 'Ex: 123456789',
        password: 'Password',
        password_placeholder: 'Access password',
        group: 'Group',
        description: 'Description',
        description_placeholder: 'Additional notes...',
        color: 'Color',
        save_current_color: 'Save current color as preset',
        os_type: 'Operating system',
        os_type_placeholder: 'Not specified',
        name_id_required: 'Name and ID are required',
        device_created: 'Device created',
        device_updated: 'Device updated',
        device_deleted: 'Device deleted',
        delete_device_confirm: 'Delete this device?',
        device_exists_unassigned: 'This ID already exists in "Unassigned". Edit it from there to assign a group.',

        // Group modal
        new_group_title: 'New Group',
        edit_group_title: 'Edit Group',
        group_name: 'Name',
        group_name_placeholder: 'Ex: Madrid Office',
        group_category: 'Category',
        name_required: 'Name is required',
        group_created: 'Group created',
        group_updated: 'Group updated',
        group_deleted: 'Group deleted',
        delete_group_confirm: 'Delete this group? Devices will not be deleted.',

        // Category modal
        new_category_title: 'New Category',
        edit_category_title: 'Edit Category',
        category_name: 'Name',
        category_name_placeholder: 'Ex: Clients',
        category_created: 'Category created',
        category_updated: 'Category updated',
        category_deleted: 'Category deleted',
        delete_category_confirm: 'Delete this category? Groups will become uncategorized.',

        // Settings
        settings_title: 'Settings',
        api_server: 'API Server',
        server_url: 'Server URL',
        server_url_placeholder: 'https://server:21114',
        username: 'Username',
        username_placeholder: 'admin',
        password_settings: 'Password',
        password_keep_placeholder: 'Leave empty to keep',
        password_new_placeholder: 'Enter password',
        password_hint: 'Password saved. Type to change.',
        rustdesk_key: 'RustDesk Key',
        rustdesk_key_placeholder: 'ABCD1234...',
        test_connection: 'Test connection',
        connection_success: 'Connection successful',
        connection_error: 'Connection error',

        sync_section: 'Sync',
        auto_sync: 'Auto sync',
        sync_interval: 'Interval (seconds)',

        rustdesk_section: 'RustDesk',
        default_password: 'Default password',
        default_password_placeholder: 'Password for new devices',

        language_section: 'Language',
        language: 'Application language',

        import_export_section: 'Import / Export',
        export_data: 'Export data',
        export_data_desc: 'Download database and configuration',
        import_data: 'Import data',
        import_data_desc: 'Restore from backup file',
        export_success: 'Data exported successfully',
        import_success: 'Data imported successfully. Restarting...',
        import_error: 'Error importing data',
        select_backup_file: 'Select backup file (.zip)',

        settings_saved: 'Settings saved',
        settings_save_error: 'Error saving',

        // Status
        status_updated: 'Status updated from server',
        status_update_error: 'Error updating status',
        status_online: 'Online',
        status_offline: 'Offline',
        status_unknown: 'Unknown',
        click_to_change: 'Click to change',

        // Sync
        sync_complete: 'All synced',
        new_devices_imported: 'new devices imported',
        new_device_notification: 'New device',

        // Table headers
        col_name: 'Name',
        col_id: 'ID',
        col_group: 'Group',
        col_os: 'OS',
        col_description: 'Description',
        col_actions: 'Actions',

        // Theme
        toggle_theme: 'Toggle theme',
        refresh: 'Refresh status'
    },

    fr: {
        // General
        app_name: 'RustDesk Manager',
        save: 'Enregistrer',
        cancel: 'Annuler',
        delete: 'Supprimer',
        edit: 'Modifier',
        close: 'Fermer',
        loading: 'Chargement...',
        error: 'Erreur',
        success: 'Succès',
        confirm: 'Confirmer',
        yes: 'Oui',
        no: 'Non',

        // Sidebar
        all_devices: 'Tous les appareils',
        unassigned: 'Non classé',
        no_group: 'Sans groupe',
        categories: 'Catégories',
        no_category: 'Sans catégorie',
        add_group: 'Ajouter un groupe',
        new_device: 'Nouvel appareil',
        settings: 'Paramètres',
        coffee_link: 'Offrez un café au développeur',

        // Search
        search_placeholder: 'Rechercher des appareils...',
        search_results: 'Résultats',
        no_results: 'Aucun appareil trouvé',

        // Device card
        devices: 'appareils',
        view_password: 'Voir le mot de passe',
        no_password: 'Sans mot de passe',
        connect: 'Connecter',
        file_transfer: 'Transfert de fichiers',
        connecting: 'Connexion...',
        opening_transfer: 'Ouverture du transfert de fichiers...',

        // Device modal
        new_device_title: 'Nouvel appareil',
        edit_device_title: 'Modifier l\'appareil',
        device_name: 'Nom',
        device_name_placeholder: 'Ex: Bureau principal',
        rustdesk_id: 'ID RustDesk',
        rustdesk_id_placeholder: 'Ex: 123456789',
        password: 'Mot de passe',
        password_placeholder: 'Mot de passe d\'accès',
        group: 'Groupe',
        description: 'Description',
        description_placeholder: 'Notes supplémentaires...',
        color: 'Couleur',
        save_current_color: 'Enregistrer la couleur actuelle',
        os_type: 'Système d\'exploitation',
        os_type_placeholder: 'Non spécifié',
        name_id_required: 'Nom et ID sont obligatoires',
        device_created: 'Appareil créé',
        device_updated: 'Appareil mis à jour',
        device_deleted: 'Appareil supprimé',
        delete_device_confirm: 'Supprimer cet appareil?',
        device_exists_unassigned: 'Cet ID existe déjà dans "Non classé". Modifiez-le depuis là pour assigner un groupe.',

        // Group modal
        new_group_title: 'Nouveau groupe',
        edit_group_title: 'Modifier le groupe',
        group_name: 'Nom',
        group_name_placeholder: 'Ex: Bureau de Madrid',
        group_category: 'Catégorie',
        name_required: 'Le nom est obligatoire',
        group_created: 'Groupe créé',
        group_updated: 'Groupe mis à jour',
        group_deleted: 'Groupe supprimé',
        delete_group_confirm: 'Supprimer ce groupe? Les appareils ne seront pas supprimés.',

        // Category modal
        new_category_title: 'Nouvelle catégorie',
        edit_category_title: 'Modifier la catégorie',
        category_name: 'Nom',
        category_name_placeholder: 'Ex: Clients',
        category_created: 'Catégorie créée',
        category_updated: 'Catégorie mise à jour',
        category_deleted: 'Catégorie supprimée',
        delete_category_confirm: 'Supprimer cette catégorie? Les groupes deviendront non catégorisés.',

        // Settings
        settings_title: 'Paramètres',
        api_server: 'Serveur API',
        server_url: 'URL du serveur',
        server_url_placeholder: 'https://serveur:21114',
        username: 'Utilisateur',
        username_placeholder: 'admin',
        password_settings: 'Mot de passe',
        password_keep_placeholder: 'Laisser vide pour conserver',
        password_new_placeholder: 'Entrez le mot de passe',
        password_hint: 'Mot de passe enregistré. Tapez pour changer.',
        rustdesk_key: 'Clé RustDesk',
        rustdesk_key_placeholder: 'ABCD1234...',
        test_connection: 'Tester la connexion',
        connection_success: 'Connexion réussie',
        connection_error: 'Erreur de connexion',

        sync_section: 'Synchronisation',
        auto_sync: 'Sync automatique',
        sync_interval: 'Intervalle (secondes)',

        rustdesk_section: 'RustDesk',
        default_password: 'Mot de passe par défaut',
        default_password_placeholder: 'Mot de passe pour nouveaux appareils',

        language_section: 'Langue',
        language: 'Langue de l\'application',

        import_export_section: 'Importer / Exporter',
        export_data: 'Exporter les données',
        export_data_desc: 'Télécharger la base de données et la configuration',
        import_data: 'Importer des données',
        import_data_desc: 'Restaurer depuis un fichier de sauvegarde',
        export_success: 'Données exportées avec succès',
        import_success: 'Données importées avec succès. Redémarrage...',
        import_error: 'Erreur lors de l\'importation',
        select_backup_file: 'Sélectionner le fichier de sauvegarde (.zip)',

        settings_saved: 'Paramètres enregistrés',
        settings_save_error: 'Erreur lors de l\'enregistrement',

        // Status
        status_updated: 'État mis à jour depuis le serveur',
        status_update_error: 'Erreur de mise à jour de l\'état',
        status_online: 'En ligne',
        status_offline: 'Hors ligne',
        status_unknown: 'Inconnu',
        click_to_change: 'Cliquer pour changer',

        // Sync
        sync_complete: 'Tout synchronisé',
        new_devices_imported: 'nouveaux appareils importés',
        new_device_notification: 'Nouvel appareil',

        // Table headers
        col_name: 'Nom',
        col_id: 'ID',
        col_group: 'Groupe',
        col_os: 'SE',
        col_description: 'Description',
        col_actions: 'Actions',

        // Theme
        toggle_theme: 'Changer de thème',
        refresh: 'Actualiser l\'état'
    }
};

const supportedLanguages = [
    { code: 'es', name: 'Español' },
    { code: 'en', name: 'English' },
    { code: 'fr', name: 'Français' }
];

function getTranslations(lang = 'es') {
    return translations[lang] || translations.es;
}

function t(key, lang = 'es') {
    const trans = getTranslations(lang);
    return trans[key] || key;
}

module.exports = {
    translations,
    supportedLanguages,
    getTranslations,
    t
};
