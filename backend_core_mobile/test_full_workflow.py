# test_full_workflow.py
import sys
import uuid
from dotenv import load_dotenv
load_dotenv()

from app.database.session import SessionLocal
from app.models.usuario_model import Usuario
from app.models.cliente_model import Cliente
from app.models.solicitud_model import SolicitudCredito
from app.models.credito_model import Credito
from app.models.cronograma_model import CronogramaPago
from app.models.cuenta_model import CuentaAhorro
from app.models.movimiento_model import Movimiento
from app.services import solicitud_service, comite_service, desembolso_service, cuenta_service
from app.schemas.solicitud_schema import SolicitudCreditoCreate, ComiteDecisionRequest
from app.schemas.cuenta_schema import PagoCreditoRequest

def test_workflow():
    db = SessionLocal()
    try:
        print("1. Resolving client Carlos Mendoza (DNI: 41884031)...")
        user = db.query(Usuario).filter(Usuario.documento == "41884031").first()
        if not user:
            print("FAILED: User 41884031 not found.")
            return False
            
        cliente = db.query(Cliente).filter(Cliente.id_usuario == user.id_usuario).first()
        if not cliente:
            print("FAILED: Cliente not found for user.")
            return False
            
        negocio = cliente.negocios[0]
        print(f"   Found Cliente: ID={cliente.id_cliente}, Negocio: ID={negocio.id_negocio}")
        
        # Get product
        from app.repositories import solicitud_repository
        prods = solicitud_repository.get_productos(db)
        if not prods:
            print("FAILED: No products found.")
            return False
        prod = prods[0]
        
        print("\n2. Creating request from client...")
        req_create = SolicitudCreditoCreate(
            id_cliente=cliente.id_cliente,
            id_negocio=negocio.id_negocio,
            id_producto_credito=prod.id_producto_credito,
            monto_solicitado=10000.0,
            plazo_meses=12,
            con_seguro_desgravamen=True,
            garantia="Sola Firma",
            destino_credito="Capital de trabajo para bodega",
            lat_captura=-12.046374,
            lng_captura=-77.042793
        )
        sol = solicitud_service.crear_solicitud_cliente(db, user.id_usuario, req_create)
        print(f"   Request created: ID={sol.id_solicitud}, Exp={sol.numero_expediente}, Advisor={sol.id_asesor}, Estado={sol.estado}")
        
        print("\n3. Advisor running Preevaluation...")
        eval_res = solicitud_service.preevaluar_solicitud_asesor(db, sol.id_solicitud)
        print(f"   Preevaluation result: {eval_res['resultado']} (Score: {eval_res['puntaje']})")
        
        print("\n4. Advisor running Bureau Check...")
        from app.services import buro_service
        buro_res = buro_service.consultar_buro(db, sol.id_solicitud)
        print(f"   Bureau result: {buro_res['calificacion']} (Status: {buro_res['resultado']})")
        
        # Set state to RECEIVED and IN_EVALUATION like the supervisor screen does
        print("\n5. Supervisor/Committee receiving and evaluating request...")
        sol = comite_service.recibir_solicitud(db, sol.id_solicitud)
        sol = comite_service.evaluar_solicitud(db, sol.id_solicitud)
        print(f"   State updated to: {sol.estado}")
        
        print("\n6. Supervisor/Committee approving request...")
        sol = comite_service.aprobar_solicitud(db, sol.id_solicitud, 10000.0, "Garantía aprobada con aval")
        print(f"   Approved! State: {sol.estado}, Approved Amount: {sol.monto_aprobado}")
        
        # Check client's account balance before disbursement
        accounts = cuenta_service.get_cuentas_by_cliente_id(db, cliente.id_cliente)
        if not accounts:
            print("FAILED: Client has no accounts.")
            return False
        cta = accounts[0]
        initial_balance = float(cta.saldo_disponible)
        print(f"\n7. Initial account balance: S/ {initial_balance}")
        
        print("\n8. Supervisor/Committee disbursing request...")
        cred = desembolso_service.desembolsar_solicitud(db, sol.id_solicitud)
        print(f"   Disbursed! Credit ID: {cred.id_credito}, Number: {cred.numero_credito}, Estado: {cred.estado}")
        
        # Refresh account balance
        db.refresh(cta)
        post_disb_balance = float(cta.saldo_disponible)
        print(f"   Post-disbursement balance: S/ {post_disb_balance}")
        if post_disb_balance != initial_balance + 10000.0:
            print("FAILED: Account was not correctly credited.")
            return False
        print("   SUCCESS: Account credited correctly!")
        
        # Fetch payment schedule (cronograma)
        from app.services import cronograma_service
        crono = cronograma_service.get_cronograma_by_credito_id(db, cred.id_credito)
        print(f"   Schedule generated with {len(crono)} installments.")
        if len(crono) != 12:
            print(f"FAILED: Expected 12 installments, got {len(crono)}.")
            return False
        
        # Let's pay the first installment
        cuota1 = crono[0]
        installment_amount = float(cuota1.monto_cuota)
        print(f"\n9. Paying installment 1 (Amount: S/ {installment_amount})...")
        pay_req = PagoCreditoRequest(
            cuenta_origen_id=cta.id_cuenta,
            credito_id=cred.id_credito,
            monto=installment_amount,
            numero_cuota=1
        )
        cuenta_service.pagar_cuota_credito(db, cliente.id_cliente, pay_req)
        
        # Refresh cuota and account balance
        db.refresh(cuota1)
        db.refresh(cta)
        print(f"   Installment 1 state post-payment: {cuota1.estado}")
        print(f"   Account balance post-payment: S/ {cta.saldo_disponible}")
        if cuota1.estado != "PAGADA":
            print("FAILED: Installment state is not PAGADA.")
            return False
        if float(cta.saldo_disponible) != post_disb_balance - installment_amount:
            print("FAILED: Account balance was not correctly debited.")
            return False
        print("   SUCCESS: Installment paid and debited correctly!")
        
        print("\n=== ALL WORKFLOW STEPS PASSED SUCCESSFULLY ===")
        
        db.rollback()
        print("Rollback successful. DB is clean.")
        return True
        
    except Exception as e:
        print("FAILED WITH EXCEPTION:", e)
        import traceback
        traceback.print_exc()
        db.rollback()
        return False
    finally:
        db.close()

if __name__ == "__main__":
    success = test_workflow()
    sys.exit(0 if success else 1)
