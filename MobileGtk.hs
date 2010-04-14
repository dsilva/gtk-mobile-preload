{-# LANGUAGE ForeignFunctionInterface #-}

{- Copyright 2010 Daniel Silva
   Distributed under the AGPL v3.  See LICENSE file.
-}

-- ghc --make -dynamic -shared -fPIC MobileGtk.hs -o libmobilegtk.so  /usr/lib/ghc-6.12.1/libHSrts-ghc6.12.1.so -optl-Wl,-rpath,/usr/lib/ghc-6.12.1/ -optc '-DMODULE=MobileGtk' init.c

-- needs libgtk-x11-2.0.so

module MobileGtk where

import Foreign.C.Types
import Foreign.C.String
import Foreign
import Foreign.Ptr(nullPtr)
import System.Posix.DynamicLinker
import System.Posix.DynamicLinker.Prim(c_dlsym)
import Control.Monad(fmap)

type GtkWidget = Ptr ()
type GObjectClass = Ptr ()
type GtkContainer = Ptr ()
type GnomeApp = Ptr ()
type GtkToolbar = Ptr ()
type GtkScrolledWindow = Ptr ()
type GtkAdjustment = Ptr ()
type GtkFrame = Ptr ()

foreign import ccall gobj_type :: GtkWidget -> CInt
foreign import ccall gobj_get_class :: GtkWidget -> GObjectClass
foreign import ccall gobj_type_name :: GtkWidget -> CString

type WVFun = GtkWidget -> IO ()
foreign import ccall "dynamic" mkWVFun :: FunPtr WVFun -> WVFun

type WidgetWidgetFun = GtkWidget -> GtkWidget -> IO ()
foreign import ccall "dynamic" mkWidgetWidgetFun :: FunPtr WidgetWidgetFun -> WidgetWidgetFun

type CWVFun = GtkContainer -> GtkWidget -> IO ()
foreign import ccall "dynamic" mkCWVFun :: FunPtr CWVFun -> CWVFun

type PPVFun = Ptr () -> Ptr () -> IO ()
foreign import ccall "dynamic" mkPPVFun :: FunPtr PPVFun -> PPVFun

foreign import ccall "gtk/gtk.h gtk_scrolled_window_new" gtk_scrolled_window_new :: GtkAdjustment -> GtkAdjustment -> GtkWidget
foreign import ccall "gtk/gtk.h gtk_scrolled_window_get_hscrollbar" gtk_scrolled_window_get_hscrollbar :: GtkScrolledWindow -> GtkWidget

foreign import ccall "gtk/gtk.h gtk_widget_hide" gtk_widget_hide :: GtkWidget -> IO ()

--foreign import ccall "gtk/gtk.h gtk_widget_show" orig_gtk_widget_show :: GtkWidget -> IO ()

foreign import ccall "gtk/gtk.h gtk_scrolled_window_set_policy" gtk_scrolled_window_set_policy :: GtkScrolledWindow -> CInt -> CInt -> IO ()

foreign import ccall "gtk/gtk.h gtk_widget_hide_all" gtk_widget_hide_all :: GtkWidget -> IO ()

foreign import ccall "gtk/gtk.h gtk_frame_get_label" gtk_frame_get_label :: GtkFrame -> IO CString

foreign import ccall hildon_button_new_with_text :: CInt -> CInt -> CString -> CString -> IO GtkWidget

---- Need to dlsym with RTLD_NEXT by hand until this ubuntu packaging bug is fixed: https://bugs.launchpad.net/ubuntu/+source/ghc6/+bug/560502
--foreign import ccall unsafe "__hsunix_rtldNext" rtldNext :: Ptr a
foreign import ccall unsafe "dlsym"  next_dlsym  :: CInt -> CString -> IO (FunPtr a)
next :: String -> IO (FunPtr a)
next symbol = do
  withCString symbol $ \ s -> do
      next_dlsym (-1) s

nextM mk symbol = fmap mk $ next symbol

orig_gtk_widget_show = nextM mkWVFun "gtk_widget_show"

gtk_widget_show :: GtkWidget -> IO ()
gtk_widget_show w = do
  typename <- peekCString $ gobj_type_name w
  putStrLn ("showing widget of type " ++ typename)
  case typename of
    "GtkMenuBar" -> return ()
    --"GtkToolbar" -> return ()
    "GtkFrame" -> do
      cstr <- gtk_frame_get_label w
      putStrLn "got the c string"
      label <- if (cstr == nullPtr) then return "" else peekCString cstr
      putStrLn "got the label"
      case label of
        "Search results :" -> do
          orig <- orig_gtk_widget_show
          orig w
        _ -> return ()
      {-
      gtk_widget_hide_all w
      orig_gtk_widget_show <- nextM mkWVFun "gtk_widget_show"
      orig_gtk_widget_show w -}
    --"GtkOptionMenu" -> return ()
    --"BonoboDockBand" -> return ()
    -- GnomeAppBar is a status bar. It's clutter; just pop it up momentarily when there's some activity.
    "GnomeAppBar" -> return ()
    --"BonoboDockItemGrip" -> return ()
    --"GtkScrolledWindow" -> orig_gtk_widget_show w
    "GtkScrolledWindow" -> do
      orig_gtk_widget_show <- nextM mkWVFun "gtk_widget_show"
      orig_gtk_widget_show w
      -- hide scrollbars.  2 here is GTK_POLICY_NEVER
      gtk_scrolled_window_set_policy w 2 2
    _ -> do
    orig_gtk_widget_show <- nextM mkWVFun "gtk_widget_show"
    orig_gtk_widget_show w
    {-
    _ -> withDL "libgtk-x11-2.0.so" [RTLD_LAZY] $ \gtk -> do
           --ptr <- dlsym gtk "gtk_widget_show"
           ptr <- next "gtk_widget_show"
           let orig_gtk_widget_show = mkWidgetFun ptr
           orig_gtk_widget_show w -}

foreign export ccall "gtk_widget_show" gtk_widget_show :: GtkWidget -> IO ()

orig_gtk_container_add = nextM mkCWVFun "gtk_container_add"

gtk_container_add :: GtkContainer -> GtkWidget -> IO ()
gtk_container_add container widget = do
  widget_typename <- peekCString $ gobj_type_name widget
  container_typename <- peekCString $ gobj_type_name container
  putStrLn ("adding widget of type " ++ widget_typename ++ " to a " ++ container_typename)
  case (container_typename, widget_typename) of
    (_, "GtkMenuBar") -> return ()
    {-
    ("GtkFrame", _) -> do
      gtk_widget_hide widget
      orig <- orig_gtk_container_add
      orig container widget -}
    --(_, "GtkToolbar") -> return ()
    _ -> withDL "libgtk-x11-2.0.so" [RTLD_LAZY] $ \gtk -> do
           ptr <- dlsym gtk "gtk_container_add"
           let orig = mkCWVFun ptr
           orig container widget

foreign export ccall gtk_container_add :: GtkContainer -> GtkWidget -> IO ()

-- HildonButtonArrangement
cHILDON_BUTTON_ARRANGEMENT_HORIZONTAL = 0
cHILDON_BUTTON_ARRANGEMENT_VERTICAL = 1

-- HildonSizeType
cHILDON_SIZE_AUTO_WIDTH = 0

gtk_button_new_with_label :: CString -> IO GtkWidget
gtk_button_new_with_label label = do
  putStrLn "Intercepting gtk_button_new_with_label"
  hildon_button_new_with_text cHILDON_SIZE_AUTO_WIDTH cHILDON_BUTTON_ARRANGEMENT_HORIZONTAL label nullPtr

foreign export ccall gtk_button_new_with_label :: CString -> IO GtkWidget

gnome_app_set_toolbar :: GnomeApp -> GtkToolbar -> IO ()
gnome_app_set_toolbar app toolbar = do
  return ()

foreign export ccall gnome_app_set_toolbar :: GnomeApp -> GtkToolbar -> IO ()

