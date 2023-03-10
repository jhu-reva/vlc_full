/*****************************************************************************
 * os.c : Low-level dynamic library handling
 *****************************************************************************
 * Copyright (C) 2001-2007 the VideoLAN team
 * $Id: a449ad7b2c51fc4a69ae011ac2059fa7a578364d $
 *
 * Authors: Sam Hocevar <sam@zoy.org>
 *          Ethan C. Baldridge <BaldridgeE@cadmus.com>
 *          Hans-Peter Jansen <hpj@urpla.net>
 *          Gildas Bazin <gbazin@videolan.org>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston MA 02110-1301, USA.
 *****************************************************************************/

#ifdef HAVE_CONFIG_H
# include "config.h"
#endif

#include <vlc_common.h>
#include <vlc_plugin.h> /* MODULE_SUFFIX */
#include "libvlc.h"
#include "modules.h"

#include <stdlib.h>                                      /* free(), strtol() */
#include <stdio.h>                                              /* sprintf() */
#include <string.h>                                              /* strdup() */

#ifdef HAVE_SYS_TYPES_H
#   include <sys/types.h>
#endif

#if !defined(HAVE_DYNAMIC_PLUGINS)
    /* no support for plugins */
#elif defined(HAVE_DL_DYLD)
#   if defined(HAVE_MACH_O_DYLD_H)
#       include <mach-o/dyld.h>
#   endif
#elif defined(HAVE_DL_BEOS)
#   if defined(HAVE_IMAGE_H)
#       include <image.h>
#   endif
#elif defined(HAVE_DL_WINDOWS)
#   include <windows.h>
#elif defined(HAVE_DL_DLOPEN)
#   if defined(HAVE_DLFCN_H) /* Linux, BSD, Hurd */
#       include <dlfcn.h>
#   endif
#   if defined(HAVE_SYS_DL_H)
#       include <sys/dl.h>
#   endif
#elif defined(HAVE_DL_SHL_LOAD)
#   if defined(HAVE_DL_H)
#       include <dl.h>
#   endif
#endif

/*****************************************************************************
 * Local prototypes
 *****************************************************************************/
#ifdef HAVE_DYNAMIC_PLUGINS
static void * GetSymbol        ( module_handle_t, const char * );

#if defined(HAVE_DL_WINDOWS)
static char * GetWindowsError  ( void );
#endif

/**
 * module Call
 *
 * Call a symbol given its name and a module structure. The symbol MUST
 * refer to a function returning int and taking a module_t* as an argument.
 * \param p_module the modules
 * \return 0 if it pass and -1 in case of a failure
 */
int module_Call( module_t *p_module )
{
    static const char psz_name[] = "vlc_entry" MODULE_SUFFIX;
    int (* pf_symbol) ( module_t * p_module );

    /* Try to resolve the symbol */
    pf_symbol = (int (*)(module_t *)) GetSymbol( p_module->handle, psz_name );

    if( pf_symbol == NULL )
    {
#if defined(HAVE_DL_DYLD) || defined(HAVE_DL_BEOS)
        msg_Warn( p_module, "cannot find symbol \"%s\" in file `%s'",
                            psz_name, p_module->psz_filename );
#elif defined(HAVE_DL_WINDOWS)
        char *psz_error = GetWindowsError();
        msg_Warn( p_module, "cannot find symbol \"%s\" in file `%s' (%s)",
                            psz_name, p_module->psz_filename, psz_error );
        free( psz_error );
#elif defined(HAVE_DL_DLOPEN)
        msg_Warn( p_module, "cannot find symbol \"%s\" in file `%s' (%s)",
                            psz_name, p_module->psz_filename, dlerror() );
#elif defined(HAVE_DL_SHL_LOAD)
        msg_Warn( p_module, "cannot find symbol \"%s\" in file `%s' (%m)",
                            psz_name, p_module->psz_filename );
#else
#   error "Something is wrong in modules.c"
#endif
        return -1;
    }

    /* We can now try to call the symbol */
    if( pf_symbol( p_module ) != 0 )
    {
        /* With a well-written module we shouldn't have to print an
         * additional error message here, but just make sure. */
        msg_Err( p_module, "Failed to call symbol \"%s\" in file `%s'",
                           psz_name, p_module->psz_filename );
        return -1;
    }

    /* Everything worked fine, we can return */
    return 0;
}

/**
 * Load a dynamically linked library using a system dependent method.
 *
 * \param p_this vlc object
 * \param psz_file library file
 * \param p_handle the module handle returned
 * \return 0 on success as well as the module handle.
 */
int module_Load( vlc_object_t *p_this, const char *psz_file,
                 module_handle_t *p_handle )
{
    module_handle_t handle;

#if defined(HAVE_DL_DYLD)
    NSObjectFileImage image;
    NSObjectFileImageReturnCode ret;

    ret = NSCreateObjectFileImageFromFile( psz_file, &image );

    if( ret != NSObjectFileImageSuccess )
    {
        msg_Warn( p_this, "cannot create image from `%s'", psz_file );
        return -1;
    }

    /* Open the dynamic module */
    handle = NSLinkModule( image, psz_file,
                           NSLINKMODULE_OPTION_RETURN_ON_ERROR );

    if( !handle )
    {
        NSLinkEditErrors errors;
        const char *psz_file, *psz_err;
        int i_errnum;
        NSLinkEditError( &errors, &i_errnum, &psz_file, &psz_err );
        msg_Warn( p_this, "cannot link module `%s' (%s)", psz_file, psz_err );
        NSDestroyObjectFileImage( image );
        return -1;
    }

    /* Destroy our image, we won't need it */
    NSDestroyObjectFileImage( image );

#elif defined(HAVE_DL_BEOS)
    handle = load_add_on( psz_file );
    if( handle < 0 )
    {
        msg_Warn( p_this, "cannot load module `%s'", psz_file );
        return -1;
    }

#elif defined(HAVE_DL_WINDOWS)
    wchar_t psz_wfile[MAX_PATH];
    MultiByteToWideChar( CP_ACP, 0, psz_file, -1, psz_wfile, MAX_PATH );

    /* FIXME: this is not thread-safe -- Courmisch */
    UINT mode = SetErrorMode (SEM_FAILCRITICALERRORS);
    SetErrorMode (mode|SEM_FAILCRITICALERRORS);

#ifdef UNDER_CE
    handle = LoadLibrary( psz_wfile );
#else
    handle = LoadLibraryW( psz_wfile );
#endif
    SetErrorMode (mode);

    if( handle == NULL )
    {
        char *psz_err = GetWindowsError();
        msg_Warn( p_this, "cannot load module `%s' (%s)", psz_file, psz_err );
        free( psz_err );
        return -1;
    }

#elif defined(HAVE_DL_DLOPEN) && defined(RTLD_NOW)
    /* static is OK, we are called atomically */
    handle = dlopen( psz_file, RTLD_NOW );
    if( handle == NULL )
    {
        msg_Warn( p_this, "cannot load module `%s' (%s)",
                          psz_file, dlerror() );
        return -1;
    }

#elif defined(HAVE_DL_DLOPEN)
#   if defined(DL_LAZY)
    handle = dlopen( psz_file, DL_LAZY );
#   else
    handle = dlopen( psz_file, 0 );
#   endif
    if( handle == NULL )
    {
        msg_Warn( p_this, "cannot load module `%s' (%s)",
                          psz_file, dlerror() );
        return -1;
    }

#elif defined(HAVE_DL_SHL_LOAD)
    handle = shl_load( psz_file, BIND_IMMEDIATE | BIND_NONFATAL, NULL );
    if( handle == NULL )
    {
        msg_Warn( p_this, "cannot load module `%s' (%m)", psz_file );
        return -1;
    }

#else
#   error "Something is wrong in modules.c"

#endif

    *p_handle = handle;
    return 0;
}

/**
 * CloseModule: unload a dynamic library
 *
 * This function unloads a previously opened dynamically linked library
 * using a system dependent method. No return value is taken in consideration,
 * since some libraries sometimes refuse to close properly.
 * \param handle handle of the library
 * \return nothing
 */
void module_Unload( module_handle_t handle )
{
#if defined(HAVE_DL_DYLD)
    NSUnLinkModule( handle, FALSE );

#elif defined(HAVE_DL_BEOS)
    unload_add_on( handle );

#elif defined(HAVE_DL_WINDOWS)
    FreeLibrary( handle );

#elif defined(HAVE_DL_DLOPEN)
# ifdef NDEBUG
    dlclose( handle );
# else
    (void)handle;
# endif

#elif defined(HAVE_DL_SHL_LOAD)
    shl_unload( handle );

#endif
    return;
}

/**
 * GetSymbol: get a symbol from a dynamic library
 *
 * This function queries a loaded library for a symbol specified in a
 * string, and returns a pointer to it. We don't check for dlerror() or
 * similar functions, since we want a non-NULL symbol anyway.
 * \param handle handle to the module
 * \param psz_function function name
 * \return nothing
 */
static void * _module_getsymbol( module_handle_t, const char * );

static void * GetSymbol( module_handle_t handle, const char * psz_function )
{
    void * p_symbol = _module_getsymbol( handle, psz_function );

    /* MacOS X dl library expects symbols to begin with "_". So do
     * some other operating systems. That's really lame, but hey, what
     * can we do ? */
    if( p_symbol == NULL )
    {
        char psz_call[strlen( psz_function ) + 2];

        psz_call[ 0 ] = '_';
        memcpy( psz_call + 1, psz_function, sizeof (psz_call) - 1 );
        p_symbol = _module_getsymbol( handle, psz_call );
    }

    return p_symbol;
}

static void * _module_getsymbol( module_handle_t handle,
                                 const char * psz_function )
{
#if defined(HAVE_DL_DYLD)
    NSSymbol sym = NSLookupSymbolInModule( handle, psz_function );
    return NSAddressOfSymbol( sym );

#elif defined(HAVE_DL_BEOS)
    void * p_symbol;
    if( B_OK == get_image_symbol( handle, psz_function,
                                  B_SYMBOL_TYPE_TEXT, &p_symbol ) )
    {
        return p_symbol;
    }
    else
    {
        return NULL;
    }

#elif defined(HAVE_DL_WINDOWS) && defined(UNDER_CE)
    wchar_t psz_real[256];
    MultiByteToWideChar( CP_ACP, 0, psz_function, -1, psz_real, 256 );

    return (void *)GetProcAddress( handle, psz_real );

#elif defined(HAVE_DL_WINDOWS) && defined(WIN32)
    return (void *)GetProcAddress( handle, (char *)psz_function );

#elif defined(HAVE_DL_DLOPEN)
    return dlsym( handle, psz_function );

#elif defined(HAVE_DL_SHL_LOAD)
    void *p_sym;
    shl_findsym( &handle, psz_function, TYPE_UNDEFINED, &p_sym );
    return p_sym;

#endif
}

#if defined(HAVE_DL_WINDOWS)
static char * GetWindowsError( void )
{
#if defined(UNDER_CE)
    wchar_t psz_tmp[MAX_PATH];
    char * psz_buffer = malloc( MAX_PATH );
#else
    char * psz_tmp = malloc( MAX_PATH );
#endif
    int i = 0, i_error = GetLastError();

    FormatMessage( FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_IGNORE_INSERTS,
                   NULL, i_error, MAKELANGID (LANG_NEUTRAL, SUBLANG_DEFAULT),
                   (LPTSTR)psz_tmp, MAX_PATH, NULL );

    /* Go to the end of the string */
    while( psz_tmp[i] && psz_tmp[i] != _T('\r') && psz_tmp[i] != _T('\n') )
    {
        i++;
    }

    if( psz_tmp[i] )
    {
#if defined(UNDER_CE)
        swprintf( psz_tmp + i, L" (error %i)", i_error );
        psz_tmp[ 255 ] = L'\0';
#else
        snprintf( psz_tmp + i, 256 - i, " (error %i)", i_error );
        psz_tmp[ 255 ] = '\0';
#endif
    }

#if defined(UNDER_CE)
    wcstombs( psz_buffer, psz_tmp, MAX_PATH );
    return psz_buffer;
#else
    return psz_tmp;
#endif
}
#endif /* HAVE_DL_WINDOWS */
#endif /* HAVE_DYNAMIC_PLUGINS */
